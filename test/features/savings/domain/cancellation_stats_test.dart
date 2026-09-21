import 'package:flutter_test/flutter_test.dart';
import 'package:lapse/core/domain/money.dart';
import 'package:lapse/features/savings/domain/cancellation_stats.dart';
import 'package:lapse/features/subscriptions/domain/entities/billing_period.dart';
import 'package:lapse/features/subscriptions/domain/entities/subscription.dart';
import 'package:lapse/features/subscriptions/domain/entities/subscription_status.dart';
import 'package:lapse/features/subscriptions/domain/services/billing_engine.dart';

import '../../../helpers/subscription_fixtures.dart';

Subscription _cancelled(
  String id,
  DateTime at, {
  int priceMinor = 29900,
  String currency = 'PKR',
  BillingPeriod period = BillingPeriod.monthly,
}) => subscriptionFixture(
  id: id,
  priceMinor: priceMinor,
  currency: currency,
  period: period,
  status: SubscriptionStatus.cancelled,
).copyWith(cancelledAt: at);

void main() {
  const engine = BillingEngine();

  group('cancelledThisYear', () {
    final now = DateTime(2026, 9, 21, 10);

    test('counts only cancellations in the current local year', () {
      final subs = [
        _cancelled('a', DateTime(2026)),
        _cancelled('b', DateTime(2025, 12, 31, 23, 59)),
        _cancelled('c', DateTime(2026, 9, 21, 9)),
      ];

      expect(CancellationStats.cancelledThisYear(subs, now), 2);
    });

    test('31 Dec counts in its own year, 1 Jan in the next', () {
      final subs = [
        _cancelled('a', DateTime(2026, 12, 31, 23, 59)),
        _cancelled('b', DateTime(2027)),
      ];

      expect(CancellationStats.cancelledThisYear(subs, DateTime(2026, 12)), 1);
      expect(CancellationStats.cancelledThisYear(subs, DateTime(2027)), 1);
    });

    test('uses local time for UTC timestamps', () {
      final local = DateTime(2027, 1, 1, 0, 30);
      final subs = [_cancelled('a', local.toUtc())];

      expect(CancellationStats.cancelledThisYear(subs, DateTime(2027, 2)), 1);
      expect(CancellationStats.cancelledThisYear(subs, DateTime(2026, 2)), 0);
    });

    test('restored and active subscriptions do not count', () {
      final restored = _cancelled(
        'a',
        DateTime(2026, 3),
      ).copyWith(status: SubscriptionStatus.active);
      final subs = [
        restored,
        subscriptionFixture(id: 'b'),
        _cancelled('c', DateTime(2026, 4)),
      ];

      expect(CancellationStats.cancelledThisYear(subs, now), 1);
    });

    test('empty list is zero', () {
      expect(CancellationStats.cancelledThisYear(const [], now), 0);
    });
  });

  group('savedPerYear and cancelledCount', () {
    final subs = [
      _cancelled('a', DateTime(2026, 3), priceMinor: 64900),
      _cancelled(
        'b',
        DateTime(2026, 4),
        priceMinor: 778800,
        period: BillingPeriod.yearly,
      ),
      _cancelled('c', DateTime(2026, 5), priceMinor: 999, currency: 'USD'),
      subscriptionFixture(id: 'd', priceMinor: 100000),
    ];

    test('sums yearly cost of cancelled subscriptions in the currency', () {
      expect(
        CancellationStats.savedPerYear(subs, 'PKR', engine),
        const Money(64900 * 12 + 778800, 'PKR'),
      );
      expect(
        CancellationStats.savedPerYear(subs, 'USD', engine),
        const Money(999 * 12, 'USD'),
      );
    });

    test('is zero when nothing is cancelled in the currency', () {
      expect(
        CancellationStats.savedPerYear(subs, 'EUR', engine),
        const Money.zero('EUR'),
      );
    });

    test('counts cancelled subscriptions per currency', () {
      expect(CancellationStats.cancelledCount(subs, 'PKR'), 2);
      expect(CancellationStats.cancelledCount(subs, 'USD'), 1);
      expect(CancellationStats.cancelledCount(subs, 'EUR'), 0);
    });
  });
}
