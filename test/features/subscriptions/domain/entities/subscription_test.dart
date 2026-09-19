import 'package:flutter_test/flutter_test.dart';
import 'package:lapse/core/domain/calendar_date.dart';
import 'package:lapse/features/subscriptions/domain/entities/billing_period.dart';
import 'package:lapse/features/subscriptions/domain/entities/charge.dart';
import 'package:lapse/features/subscriptions/domain/entities/subscription.dart';
import 'package:lapse/features/subscriptions/domain/entities/subscription_status.dart';

import '../../../../helpers/subscription_fixtures.dart';

void main() {
  final base = subscriptionFixture(cancelUrl: 'https://example.com/cancel');

  group('copyWith', () {
    test('keeps every field when nothing is passed', () {
      expect(base.copyWith(), base);
    });

    test('changes the fields that are passed', () {
      final changed = base.copyWith(name: 'Spotify Family', isTrial: true);
      expect(changed.name, 'Spotify Family');
      expect(changed.isTrial, isTrue);
      expect(changed.price, base.price);
    });

    test('can clear nullable fields with an explicit null', () {
      final withNotes = base.copyWith(notes: 'shared with family');
      expect(withNotes.notes, 'shared with family');

      final cleared = withNotes.copyWith(notes: null, cancelUrl: null);
      expect(cleared.notes, isNull);
      expect(cleared.cancelUrl, isNull);
    });
  });

  group('equality', () {
    test('compares reminder offsets by value', () {
      expect(
        subscriptionFixture(reminderOffsets: [7, 1]),
        subscriptionFixture(reminderOffsets: [7, 1]),
      );
      expect(
        subscriptionFixture(reminderOffsets: [7, 1]) ==
            subscriptionFixture(reminderOffsets: [3]),
        isFalse,
      );
      expect(
        subscriptionFixture().hashCode,
        subscriptionFixture().hashCode,
      );
    });

    test('reminder offsets cannot be modified from outside', () {
      expect(() => base.reminderOffsets.add(3), throwsUnsupportedError);
    });
  });

  test('status helpers', () {
    expect(base.isActive, isTrue);
    expect(base.isCancelled, isFalse);
    final cancelled = base.copyWith(status: SubscriptionStatus.cancelled);
    expect(cancelled.isActive, isFalse);
    expect(cancelled.isCancelled, isTrue);
    expect(base.isUnsaved, isFalse);
    expect(base.copyWith(id: Subscription.unsavedId).isUnsaved, isTrue);
  });

  test('toString is readable', () {
    expect(base.toString(), contains('Spotify Premium'));
    expect(base.copyWith(isTrial: true).toString(), contains('trial'));
  });

  test('enums parse from storage', () {
    expect(BillingPeriod.fromStorage('customDays'), BillingPeriod.customDays);
    expect(BillingPeriod.fromStorage('fortnightly'), isNull);
    expect(
      SubscriptionStatus.fromStorage('cancelled'),
      SubscriptionStatus.cancelled,
    );
    expect(SubscriptionStatus.fromStorage('paused'), isNull);
  });

  test('charges compare by value', () {
    Charge charge() => Charge(
      id: 'c1',
      subscriptionId: 'sub-1',
      amount: base.price,
      chargedOn: CalendarDate(2026, 9, 1),
    );
    expect(charge(), charge());
    expect(charge().hashCode, charge().hashCode);
    expect(charge().toString(), contains('2026-09-01'));
  });
}
