import 'package:flutter_test/flutter_test.dart';
import 'package:lapse/core/domain/calendar_date.dart';
import 'package:lapse/core/domain/money.dart';
import 'package:lapse/features/subscriptions/data/mappers/charge_mapper.dart';
import 'package:lapse/features/subscriptions/data/mappers/subscription_mapper.dart';
import 'package:lapse/features/subscriptions/domain/entities/billing_period.dart';
import 'package:lapse/features/subscriptions/domain/entities/charge.dart';
import 'package:lapse/features/subscriptions/domain/entities/subscription_status.dart';

import '../../../../helpers/subscription_fixtures.dart';

void main() {
  group('SubscriptionMapper', () {
    test('round trips every field', () {
      final full =
          subscriptionFixture(
            period: BillingPeriod.customDays,
            customDays: 45,
            isTrial: true,
            reminderOffsets: [7, 3, 1],
            cancelUrl: 'https://example.com/cancel',
            status: SubscriptionStatus.cancelled,
          ).copyWith(
            catalogKey: 'spotify',
            category: 'Music',
            paymentMethod: 'HBL ···· 4417',
            notes: 'family plan',
            cancelledAt: DateTime.utc(2026, 9, 10, 12),
            snoozedUntil: DateTime.utc(2026, 9, 12, 9),
          );

      expect(SubscriptionMapper.fromRow(SubscriptionMapper.toRow(full)), full);
    });

    test('round trips nulls and empty reminders', () {
      final minimal = subscriptionFixture(reminderOffsets: []);

      final row = SubscriptionMapper.toRow(minimal);

      expect(row['reminder_offsets'], '');
      expect(row['is_trial'], 0);
      expect(SubscriptionMapper.fromRow(row), minimal);
    });

    test('stores dates as ISO text and timestamps in UTC', () {
      final row = SubscriptionMapper.toRow(
        subscriptionFixture(nextBillingDate: CalendarDate(2026, 10, 1)),
      );

      expect(row['next_billing_date'], '2026-10-01');
      expect(row['created_at'], '2026-09-01T08:00:00.000Z');
    });

    test('rejects unknown enum values', () {
      final row = SubscriptionMapper.toRow(subscriptionFixture())
        ..['period'] = 'fortnightly';

      expect(() => SubscriptionMapper.fromRow(row), throwsFormatException);
    });
  });

  test('ChargeMapper round trips', () {
    final charge = Charge(
      id: 'c1',
      subscriptionId: 'sub-1',
      amount: const Money(29900, 'PKR'),
      chargedOn: CalendarDate(2026, 9, 1),
    );

    expect(ChargeMapper.fromRow(ChargeMapper.toRow(charge)), charge);
  });
}
