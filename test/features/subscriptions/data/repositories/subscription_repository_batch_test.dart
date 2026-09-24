import 'package:flutter_test/flutter_test.dart';
import 'package:lapse/core/database/schema.dart';
import 'package:lapse/core/domain/calendar_date.dart';
import 'package:lapse/core/domain/money.dart';
import 'package:lapse/features/subscriptions/data/mappers/subscription_mapper.dart';
import 'package:lapse/features/subscriptions/data/repositories/subscription_repository_impl.dart';
import 'package:lapse/features/subscriptions/domain/entities/charge.dart';
import 'package:lapse/features/subscriptions/domain/entities/subscription.dart';
import 'package:lapse/features/subscriptions/domain/services/billing_engine.dart';
import 'package:lapse/features/subscriptions/domain/usecases/roll_over_due_subscriptions.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../../helpers/subscription_fixtures.dart';
import '../../../../helpers/test_clock.dart';
import '../../../../helpers/test_database.dart';

void main() {
  late Database db;
  late SubscriptionRepositoryImpl repository;

  setUp(() async {
    db = await openTestDatabase();
    repository = SubscriptionRepositoryImpl(db);
  });

  tearDown(() async {
    await repository.dispose();
    await db.close();
  });

  Charge charge(
    String id, {
    String subscriptionId = 'sub-1',
    CalendarDate? on,
  }) => Charge(
    id: id,
    subscriptionId: subscriptionId,
    amount: const Money(29900, 'PKR'),
    chargedOn: on ?? CalendarDate(2026, 9, 1),
  );

  Future<void> settle(int Function() count) async {
    var last = -1;
    var stable = 0;
    while (stable < 5) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
      await repository.getAll();
      final now = count();
      stable = now == last ? stable + 1 : 0;
      last = now;
    }
  }

  Future<List<List<Subscription>>> recordAll(
    Future<void> Function() body,
  ) async {
    final emissions = <List<Subscription>>[];
    final listener = repository.watchAll().listen(emissions.add);
    await settle(() => emissions.length);
    await body();
    await settle(() => emissions.length);
    await listener.cancel();
    return emissions;
  }

  group('emissions', () {
    test('writing identical data does not re-emit', () async {
      final sub = subscriptionFixture();
      await repository.upsert(sub);

      final emissions = await recordAll(() async {
        await repository.upsert(sub);
        await settle(() => 0);
        await repository.upsert(sub);
      });

      expect(emissions, [
        [sub],
      ]);
    });

    test('refresh re-emits only when the data changed', () async {
      final sub = subscriptionFixture();
      await repository.upsert(sub);

      final emissions = await recordAll(() async {
        await repository.refresh();
        await settle(() => 0);
        await db.update(
          Tables.subscriptions,
          SubscriptionMapper.toRow(sub.copyWith(name: 'Outside')),
        );
        await repository.refresh();
        await settle(() => 0);
        await repository.refresh();
      });

      expect(emissions.map((list) => list.single.name), [
        'Spotify Premium',
        'Outside',
      ]);
    });

    test('watchById skips identical values and follows refresh', () async {
      final sub = subscriptionFixture();
      await repository.upsert(sub);
      final values = <String?>[];
      final listener = repository
          .watchById('sub-1')
          .listen((s) => values.add(s?.name));
      await settle(() => values.length);

      await repository.upsert(sub);
      await settle(() => values.length);
      await repository.refresh();
      await settle(() => values.length);
      await repository.upsert(sub.copyWith(name: 'Duo'));
      await settle(() => values.length);
      await listener.cancel();

      expect(values, ['Spotify Premium', 'Duo']);
    });
  });

  group('applyRollOvers', () {
    test('150 overdue subscriptions produce one emission', () async {
      final subs = [
        for (var i = 0; i < 150; i++)
          subscriptionFixture(
            id: 'sub-${i.toString().padLeft(3, '0')}',
            nextBillingDate: CalendarDate(2026, 8, 10),
            startDate: CalendarDate(2026, 7, 10),
          ),
      ];
      await repository.replaceAll(subs, const []);
      final clock = TestClock(DateTime(2026, 9, 19, 10));
      final ids = SequentialIds();
      final useCase = RollOverDueSubscriptions(
        repository: repository,
        engine: const BillingEngine(),
        clock: clock.call,
        newId: ids.call,
      );

      late int updated;
      final emissions = await recordAll(() async {
        updated = await useCase();
      });

      expect(updated, 150);
      expect(emissions, hasLength(2));
      expect(
        emissions.last.every(
          (s) => s.nextBillingDate == CalendarDate(2026, 10, 10),
        ),
        isTrue,
      );
      expect(await repository.allCharges(), hasLength(300));
    });

    test('skips rows whose next date changed and counts the rest', () async {
      await repository.replaceAll([
        subscriptionFixture(),
        subscriptionFixture(id: 'sub-2'),
      ], const []);
      final rolled = CalendarDate(2026, 11, 1);

      final applied = await repository.applyRollOvers([
        (
          subscriptionFixture(nextBillingDate: rolled),
          [charge('c1')],
          CalendarDate(2026, 10, 1),
        ),
        (
          subscriptionFixture(id: 'sub-2', nextBillingDate: rolled),
          [charge('c2', subscriptionId: 'sub-2')],
          CalendarDate(2026, 9, 1),
        ),
        (
          subscriptionFixture(nextBillingDate: rolled),
          [charge('c3')],
          CalendarDate(2026, 10, 1),
        ),
      ]);

      expect(applied, 1);
      expect((await repository.allCharges()).map((c) => c.id), ['c1']);
      expect(
        (await repository.getById('sub-2'))!.nextBillingDate,
        isNot(rolled),
      );
    });

    test('one failing subscription does not stop the others', () async {
      await repository.replaceAll([
        subscriptionFixture(),
        subscriptionFixture(id: 'sub-2'),
      ], const []);
      final rolled = CalendarDate(2026, 11, 1);
      final expected = CalendarDate(2026, 10, 1);

      final emissions = await recordAll(() async {
        final applied = await repository.applyRollOvers([
          (
            subscriptionFixture(nextBillingDate: rolled),
            [charge('dup'), charge('dup')],
            expected,
          ),
          (
            subscriptionFixture(id: 'sub-2', nextBillingDate: rolled),
            [charge('ok', subscriptionId: 'sub-2')],
            expected,
          ),
        ]);
        expect(applied, 1);
      });

      expect(emissions, hasLength(2));
      expect((await repository.getById('sub-1'))!.nextBillingDate, expected);
      expect((await repository.getById('sub-2'))!.nextBillingDate, rolled);
      expect((await repository.allCharges()).map((c) => c.id), ['ok']);
    });

    test('nothing applied means no emission', () async {
      await repository.upsert(subscriptionFixture());

      final emissions = await recordAll(() async {
        await repository.applyRollOvers([
          (
            subscriptionFixture(nextBillingDate: CalendarDate(2026, 11, 1)),
            [charge('c1')],
            CalendarDate(2026, 1, 1),
          ),
        ]);
      });

      expect(emissions, hasLength(1));
    });
  });

  test('replaceAll writes large datasets in one go', () async {
    final subs = [
      for (var i = 0; i < 400; i++) subscriptionFixture(id: 'sub-$i'),
    ];
    final charges = [
      for (var i = 0; i < 400; i++)
        charge('c-$i', subscriptionId: 'sub-${i % 400}'),
    ];

    final emissions = await recordAll(
      () => repository.replaceAll(subs, charges),
    );

    expect(emissions, hasLength(2));
    expect(emissions.last, hasLength(400));
    expect(await repository.allCharges(), hasLength(400));
  });

  test('allCharges is ordered by subscription then date', () async {
    await repository.replaceAll(
      [subscriptionFixture(id: 'b'), subscriptionFixture(id: 'a')],
      [
        charge('b2', subscriptionId: 'b', on: CalendarDate(2026, 9, 2)),
        charge('a2', subscriptionId: 'a', on: CalendarDate(2026, 9, 5)),
        charge('b1', subscriptionId: 'b', on: CalendarDate(2026, 9, 1)),
        charge('a1', subscriptionId: 'a', on: CalendarDate(2026, 8, 5)),
      ],
    );

    expect((await repository.allCharges()).map((c) => c.id), [
      'a1',
      'a2',
      'b1',
      'b2',
    ]);
  });
}
