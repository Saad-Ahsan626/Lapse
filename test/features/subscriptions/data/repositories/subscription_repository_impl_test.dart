import 'package:flutter_test/flutter_test.dart';
import 'package:lapse/core/domain/calendar_date.dart';
import 'package:lapse/core/domain/money.dart';
import 'package:lapse/features/subscriptions/data/repositories/subscription_repository_impl.dart';
import 'package:lapse/features/subscriptions/domain/entities/charge.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../../helpers/subscription_fixtures.dart';
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

  Charge charge(String id, {String subscriptionId = 'sub-1', int day = 1}) =>
      Charge(
        id: id,
        subscriptionId: subscriptionId,
        amount: const Money(29900, 'PKR'),
        chargedOn: CalendarDate(2026, 9, day),
      );

  test('schema creates both tables and indexes', () async {
    final names = (await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type IN ('table', 'index')",
    )).map((row) => row['name']).toSet();

    expect(
      names,
      containsAll([
        'subscriptions',
        'charges',
        'idx_subscriptions_next',
        'idx_charges_subscription',
      ]),
    );
  });

  test('upsert inserts, then updates in place', () async {
    final sub = subscriptionFixture();
    await repository.upsert(sub);
    await repository.upsert(sub.copyWith(name: 'Spotify Duo'));

    final all = await repository.getAll();
    expect(all, hasLength(1));
    expect(all.single.name, 'Spotify Duo');
    expect(await repository.getById('sub-1'), all.single);
    expect(await repository.getById('missing'), isNull);
  });

  test('getAll is sorted by next billing date', () async {
    await repository.upsert(
      subscriptionFixture(
        id: 'late',
        nextBillingDate: CalendarDate(2026, 12, 1),
      ),
    );
    await repository.upsert(
      subscriptionFixture(
        id: 'soon',
        nextBillingDate: CalendarDate(2026, 9, 20),
      ),
    );

    expect((await repository.getAll()).map((s) => s.id), ['soon', 'late']);
  });

  test('updating a subscription keeps its charges', () async {
    final sub = subscriptionFixture();
    await repository.applyRollOver(sub, [charge('c1')]);

    await repository.upsert(sub.copyWith(name: 'Renamed'));

    expect(await repository.chargesFor('sub-1'), hasLength(1));
  });

  test('deleting a subscription deletes its charges', () async {
    await repository.applyRollOver(subscriptionFixture(), [
      charge('c1'),
      charge('c2', day: 2),
    ]);

    await repository.delete('sub-1');

    expect(await repository.getAll(), isEmpty);
    expect(
      await db.query('charges'),
      isEmpty,
    );
  });

  test('applyRollOver is atomic', () async {
    await repository.upsert(subscriptionFixture());

    await expectLater(
      repository.applyRollOver(
        subscriptionFixture(nextBillingDate: CalendarDate(2026, 11, 1)),
        [charge('dup'), charge('dup', day: 2)],
      ),
      throwsA(isA<DatabaseException>()),
    );

    expect(
      (await repository.getById('sub-1'))!.nextBillingDate,
      CalendarDate(2026, 10, 1),
    );
    expect(await repository.chargesFor('sub-1'), isEmpty);
  });

  test('charges come back in date order', () async {
    await repository.applyRollOver(subscriptionFixture(), [
      charge('b', day: 20),
      charge('a', day: 5),
    ]);

    expect(
      (await repository.chargesFor('sub-1')).map((c) => c.id),
      ['a', 'b'],
    );
  });

  test('replaceAll swaps the whole dataset', () async {
    await repository.applyRollOver(subscriptionFixture(), [charge('c1')]);

    await repository.replaceAll(
      [subscriptionFixture(id: 'sub-2', name: 'Netflix')],
      [charge('c9', subscriptionId: 'sub-2')],
    );

    expect((await repository.getAll()).map((s) => s.id), ['sub-2']);
    expect(await repository.chargesFor('sub-1'), isEmpty);
    expect(await repository.chargesFor('sub-2'), hasLength(1));
  });

  test('watchAll emits the current list, then after every write', () async {
    final emissions = <List<String>>[];
    final subscription = repository.watchAll().listen(
      (list) => emissions.add(list.map((s) => s.name).toList()),
    );
    await pumpEventQueue();

    await repository.upsert(subscriptionFixture());
    await pumpEventQueue();
    await repository.upsert(subscriptionFixture(name: 'Spotify Duo'));
    await pumpEventQueue();
    await repository.delete('sub-1');
    await pumpEventQueue();
    await subscription.cancel();

    expect(emissions, [
      <String>[],
      ['Spotify Premium'],
      ['Spotify Duo'],
      <String>[],
    ]);
  });

  test('watchById emits null after delete', () async {
    await repository.upsert(subscriptionFixture());
    final values = <String?>[];
    final subscription = repository
        .watchById('sub-1')
        .listen((s) => values.add(s?.name));
    await pumpEventQueue();

    await repository.delete('sub-1');
    await pumpEventQueue();
    await subscription.cancel();

    expect(values, ['Spotify Premium', null]);
  });
}
