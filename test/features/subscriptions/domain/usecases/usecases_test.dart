import 'package:flutter_test/flutter_test.dart';
import 'package:lapse/core/domain/calendar_date.dart';
import 'package:lapse/core/domain/money.dart';
import 'package:lapse/core/errors/validation_exception.dart';
import 'package:lapse/features/subscriptions/domain/entities/billing_period.dart';
import 'package:lapse/features/subscriptions/domain/entities/subscription.dart';
import 'package:lapse/features/subscriptions/domain/entities/subscription_status.dart';
import 'package:lapse/features/subscriptions/domain/services/billing_engine.dart';
import 'package:lapse/features/subscriptions/domain/usecases/delete_subscription.dart';
import 'package:lapse/features/subscriptions/domain/usecases/mark_cancelled.dart';
import 'package:lapse/features/subscriptions/domain/usecases/restore_subscription.dart';
import 'package:lapse/features/subscriptions/domain/usecases/roll_over_due_subscriptions.dart';
import 'package:lapse/features/subscriptions/domain/usecases/save_subscription.dart';
import 'package:lapse/features/subscriptions/domain/validation/subscription_field.dart';
import 'package:lapse/features/subscriptions/domain/validation/subscription_validator.dart';

import '../../../../helpers/fake_subscription_repository.dart';
import '../../../../helpers/subscription_fixtures.dart';
import '../../../../helpers/test_clock.dart';

void main() {
  const engine = BillingEngine();
  late FakeSubscriptionRepository repository;
  late TestClock clock;
  late SequentialIds ids;

  setUp(() {
    repository = FakeSubscriptionRepository();
    clock = TestClock(DateTime(2026, 9, 19, 10));
    ids = SequentialIds();
  });

  group('SaveSubscription', () {
    SaveSubscription save() => SaveSubscription(
      repository: repository,
      validator: const SubscriptionValidator(),
      clock: clock.call,
      newId: ids.call,
    );

    test('creates a new subscription with id, anchor and timestamps', () async {
      final draft = subscriptionFixture(
        id: Subscription.unsavedId,
        name: '  Netflix  ',
        nextBillingDate: CalendarDate(2026, 10, 31),
        anchorDay: 1,
        reminderOffsets: [1, 7, 1],
        cancelUrl: '   ',
      );

      final saved = await save()(draft);

      expect(saved.id, 'id-0');
      expect(saved.name, 'Netflix');
      expect(saved.anchorDay, 31);
      expect(saved.reminderOffsets, [7, 1]);
      expect(saved.cancelUrl, isNull);
      expect(saved.createdAt, clock.now.toUtc());
      expect(saved.updatedAt, clock.now.toUtc());
      expect(repository.subscriptions['id-0'], saved);
    });

    test(
      'updates keep createdAt and the anchor when the date is unchanged',
      () async {
        final existing = subscriptionFixture(
          nextBillingDate: CalendarDate(2026, 2, 28),
          startDate: CalendarDate(2026, 1, 31),
          anchorDay: 31,
        );
        repository.seed([existing]);
        clock.advance(const Duration(days: 1));

        final saved = await save()(existing.copyWith(name: 'Renamed'));

        expect(saved.anchorDay, 31);
        expect(saved.createdAt, existing.createdAt);
        expect(saved.updatedAt, clock.now.toUtc());
      },
    );

    test('updates take a new anchor when the date changes', () async {
      final existing = subscriptionFixture();
      repository.seed([existing]);

      final saved = await save()(
        existing.copyWith(nextBillingDate: CalendarDate(2026, 10, 15)),
      );

      expect(saved.anchorDay, 15);
    });

    test('rejects invalid input without saving', () async {
      final draft = subscriptionFixture(
        id: Subscription.unsavedId,
        priceMinor: 0,
      );

      await expectLater(
        save()(draft),
        throwsA(
          isA<ValidationException<SubscriptionField>>().having(
            (e) => e.errors.keys,
            'fields',
            contains(SubscriptionField.price),
          ),
        ),
      );
      expect(repository.subscriptions, isEmpty);
    });
  });

  test('DeleteSubscription removes the subscription and its charges', () async {
    repository.seed([subscriptionFixture()]);
    await repository.applyRollOver(subscriptionFixture(), []);

    await DeleteSubscription(repository: repository)('sub-1');

    expect(repository.subscriptions, isEmpty);
  });

  group('MarkCancelled', () {
    test('cancels and returns the yearly amount saved', () async {
      repository.seed([subscriptionFixture(priceMinor: 64900)]);

      final saved = await MarkCancelled(
        repository: repository,
        engine: engine,
        clock: clock.call,
      )('sub-1');

      final stored = repository.subscriptions['sub-1']!;
      expect(saved, const Money(778800, 'PKR'));
      expect(stored.status, SubscriptionStatus.cancelled);
      expect(stored.cancelledAt, clock.now.toUtc());
    });

    test('throws for an unknown id', () async {
      await expectLater(
        MarkCancelled(
          repository: repository,
          engine: engine,
          clock: clock.call,
        )('missing'),
        throwsStateError,
      );
    });
  });

  group('RestoreSubscription', () {
    RestoreSubscription restore() => RestoreSubscription(
      repository: repository,
      engine: engine,
      clock: clock.call,
    );

    test('reactivates and skips dates that passed while cancelled', () async {
      repository.seed([
        subscriptionFixture(
          nextBillingDate: CalendarDate(2026, 7, 1),
          startDate: CalendarDate(2026, 6, 1),
          status: SubscriptionStatus.cancelled,
        ).copyWith(cancelledAt: DateTime.utc(2026, 6, 20)),
      ]);

      final restored = await restore()('sub-1');

      expect(restored.isActive, isTrue);
      expect(restored.cancelledAt, isNull);
      expect(restored.nextBillingDate, CalendarDate(2026, 10, 1));
      expect(repository.charges, isEmpty);
    });

    test('throws for an unknown id', () async {
      await expectLater(restore()('missing'), throwsStateError);
    });
  });

  group('RollOverDueSubscriptions', () {
    test('rolls only active overdue subscriptions and logs charges', () async {
      repository.seed([
        subscriptionFixture(
          id: 'overdue',
          nextBillingDate: CalendarDate(2026, 8, 10),
          startDate: CalendarDate(2026, 7, 10),
        ),
        subscriptionFixture(
          id: 'upcoming',
          nextBillingDate: CalendarDate(2026, 9, 25),
        ),
        subscriptionFixture(
          id: 'cancelled',
          nextBillingDate: CalendarDate(2026, 8, 1),
          startDate: CalendarDate(2026, 7, 1),
          status: SubscriptionStatus.cancelled,
        ),
      ]);

      final updated = await RollOverDueSubscriptions(
        repository: repository,
        engine: engine,
        clock: clock.call,
        newId: ids.call,
      )();

      expect(updated, 1);
      expect(
        repository.subscriptions['overdue']!.nextBillingDate,
        CalendarDate(2026, 10, 10),
      );
      expect(repository.subscriptions['overdue']!.updatedAt, clock.now.toUtc());
      expect(repository.charges.map((c) => c.chargedOn), [
        CalendarDate(2026, 8, 10),
        CalendarDate(2026, 9, 10),
      ]);
      expect(
        repository.subscriptions['cancelled']!.nextBillingDate,
        CalendarDate(2026, 8, 1),
      );
    });

    RollOverDueSubscriptions rollOver() => RollOverDueSubscriptions(
      repository: repository,
      engine: engine,
      clock: clock.call,
      newId: ids.call,
    );

    test('two concurrent runs insert one set of charges', () async {
      repository.seed([
        subscriptionFixture(
          nextBillingDate: CalendarDate(2026, 8, 10),
          startDate: CalendarDate(2026, 7, 10),
        ),
      ]);
      final useCase = rollOver();

      final results = await Future.wait([useCase(), useCase()]);

      expect(results, [1, 0]);
      expect(repository.charges.map((c) => c.chargedOn), [
        CalendarDate(2026, 8, 10),
        CalendarDate(2026, 9, 10),
      ]);
    });

    test('one bad subscription does not stop the others', () async {
      repository.seed([
        subscriptionFixture(
          id: 'broken',
          period: BillingPeriod.customDays,
          nextBillingDate: CalendarDate(2026, 8, 1),
          startDate: CalendarDate(2026, 7, 1),
        ),
        subscriptionFixture(
          id: 'fine',
          nextBillingDate: CalendarDate(2026, 8, 10),
          startDate: CalendarDate(2026, 7, 10),
        ),
      ]);

      final updated = await rollOver()();

      expect(updated, 1);
      expect(
        repository.subscriptions['fine']!.nextBillingDate,
        CalendarDate(2026, 10, 10),
      );
      expect(
        repository.subscriptions['broken']!.nextBillingDate,
        CalendarDate(2026, 8, 1),
      );
    });
  });
}
