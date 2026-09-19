import 'package:flutter_test/flutter_test.dart';
import 'package:lapse/core/domain/calendar_date.dart';
import 'package:lapse/core/domain/money.dart';
import 'package:lapse/features/subscriptions/domain/entities/billing_period.dart';
import 'package:lapse/features/subscriptions/domain/entities/subscription_status.dart';
import 'package:lapse/features/subscriptions/domain/services/billing_engine.dart';

import '../../../../helpers/subscription_fixtures.dart';
import '../../../../helpers/test_clock.dart';

void main() {
  const engine = BillingEngine();

  CalendarDate d(int y, int m, int day) => CalendarDate(y, m, day);

  List<CalendarDate> chain(
    CalendarDate start,
    BillingPeriod period,
    int count, {
    int? anchorDay,
    int? customDays,
  }) {
    final dates = [start];
    for (var i = 1; i < count; i++) {
      dates.add(
        engine.nextDate(
          dates.last,
          period,
          anchorDay: anchorDay ?? start.day,
          customDays: customDays,
        ),
      );
    }
    return dates;
  }

  group('nextDate', () {
    test('monthly on the 31st clamps and returns to the anchor', () {
      expect(chain(d(2026, 1, 31), BillingPeriod.monthly, 5), [
        d(2026, 1, 31),
        d(2026, 2, 28),
        d(2026, 3, 31),
        d(2026, 4, 30),
        d(2026, 5, 31),
      ]);
    });

    test('monthly on the 31st uses Feb 29 in leap years', () {
      expect(
        engine.nextDate(d(2028, 1, 31), BillingPeriod.monthly, anchorDay: 31),
        d(2028, 2, 29),
      );
    });

    test('yearly on Feb 29 falls back to Feb 28, then returns', () {
      expect(chain(d(2028, 2, 29), BillingPeriod.yearly, 5), [
        d(2028, 2, 29),
        d(2029, 2, 28),
        d(2030, 2, 28),
        d(2031, 2, 28),
        d(2032, 2, 29),
      ]);
    });

    test('weekly adds 7 days across a year end', () {
      expect(
        engine.nextDate(d(2026, 12, 28), BillingPeriod.weekly, anchorDay: 28),
        d(2027, 1, 4),
      );
    });

    test('quarterly adds 3 months with the anchor', () {
      expect(chain(d(2026, 11, 30), BillingPeriod.quarterly, 3), [
        d(2026, 11, 30),
        d(2027, 2, 28),
        d(2027, 5, 30),
      ]);
    });

    test('custom days adds exactly n days', () {
      expect(
        engine.nextDate(
          d(2026, 9, 19),
          BillingPeriod.customDays,
          anchorDay: 19,
          customDays: 10,
        ),
        d(2026, 9, 29),
      );
    });

    test('custom days without a valid count throws', () {
      expect(
        () => engine.nextDate(
          d(2026, 9, 19),
          BillingPeriod.customDays,
          anchorDay: 19,
        ),
        throwsArgumentError,
      );
      expect(
        () => engine.nextDate(
          d(2026, 9, 19),
          BillingPeriod.customDays,
          anchorDay: 19,
          customDays: 0,
        ),
        throwsArgumentError,
      );
    });
  });

  group('previousDate', () {
    test('mirrors nextDate for every period', () {
      final from = d(2026, 3, 31);
      expect(
        engine.previousDate(from, BillingPeriod.weekly, anchorDay: 31),
        d(2026, 3, 24),
      );
      expect(
        engine.previousDate(from, BillingPeriod.monthly, anchorDay: 31),
        d(2026, 2, 28),
      );
      expect(
        engine.previousDate(from, BillingPeriod.quarterly, anchorDay: 31),
        d(2025, 12, 31),
      );
      expect(
        engine.previousDate(from, BillingPeriod.yearly, anchorDay: 31),
        d(2025, 3, 31),
      );
      expect(
        engine.previousDate(
          from,
          BillingPeriod.customDays,
          anchorDay: 31,
          customDays: 10,
        ),
        d(2026, 3, 21),
      );
    });
  });

  group('rollOver', () {
    test('a charge due today is still upcoming', () {
      final sub = subscriptionFixture(nextBillingDate: d(2026, 9, 19));

      final result = engine.rollOver(
        sub,
        d(2026, 9, 19),
        newId: SequentialIds().call,
      );

      expect(result.changed, isFalse);
      expect(result.subscription, sub);
    });

    test('three missed cycles log three charges and move the date', () {
      final sub = subscriptionFixture(
        nextBillingDate: d(2026, 6, 30),
        startDate: d(2026, 5, 30),
        anchorDay: 30,
      );

      final result = engine.rollOver(
        sub,
        d(2026, 9, 19),
        newId: SequentialIds().call,
      );

      expect(result.charges.map((c) => c.chargedOn), [
        d(2026, 6, 30),
        d(2026, 7, 30),
        d(2026, 8, 30),
      ]);
      expect(result.charges.map((c) => c.id), ['id-0', 'id-1', 'id-2']);
      expect(
        result.charges.every((c) => c.amount == const Money(29900, 'PKR')),
        isTrue,
      );
      expect(result.charges.every((c) => c.subscriptionId == sub.id), isTrue);
      expect(result.subscription.nextBillingDate, d(2026, 9, 30));
    });

    test('a trial becomes paid after its first charge', () {
      final trial = subscriptionFixture(
        isTrial: true,
        priceMinor: 64900,
        startDate: d(2026, 9, 11),
        nextBillingDate: d(2026, 9, 18),
      );

      final result = engine.rollOver(
        trial,
        d(2026, 9, 19),
        newId: SequentialIds().call,
      );

      expect(result.charges.single.amount, const Money(64900, 'PKR'));
      expect(result.charges.single.chargedOn, d(2026, 9, 18));
      expect(result.subscription.isTrial, isFalse);
      expect(result.subscription.nextBillingDate, d(2026, 10, 18));
    });

    test('cancelled subscriptions never roll', () {
      final sub = subscriptionFixture(
        nextBillingDate: d(2026, 1, 1),
        startDate: d(2025, 12, 1),
        status: SubscriptionStatus.cancelled,
      );

      final result = engine.rollOver(
        sub,
        d(2026, 9, 19),
        newId: SequentialIds().call,
      );

      expect(result.changed, isFalse);
      expect(result.subscription.nextBillingDate, d(2026, 1, 1));
    });

    test('stops after the safety cap', () {
      final sub = subscriptionFixture(
        period: BillingPeriod.customDays,
        customDays: 1,
        startDate: d(2020, 1, 1),
        nextBillingDate: d(2020, 1, 1),
      );

      final result = engine.rollOver(
        sub,
        d(2026, 9, 19),
        newId: SequentialIds().call,
      );

      expect(result.charges, hasLength(BillingEngine.maxIterations));
    });
  });

  group('occurrencesBetween', () {
    test('lists charge dates inside the range, inclusive', () {
      final sub = subscriptionFixture(
        period: BillingPeriod.weekly,
        nextBillingDate: d(2026, 9, 3),
        startDate: d(2026, 8, 27),
      );

      expect(engine.occurrencesBetween(sub, d(2026, 9, 10), d(2026, 9, 24)), [
        d(2026, 9, 10),
        d(2026, 9, 17),
        d(2026, 9, 24),
      ]);
    });

    test('is empty for cancelled subscriptions and ranges before the date', () {
      final sub = subscriptionFixture(nextBillingDate: d(2026, 10, 1));

      expect(
        engine.occurrencesBetween(
          sub.copyWith(status: SubscriptionStatus.cancelled),
          d(2026, 9, 1),
          d(2026, 12, 31),
        ),
        isEmpty,
      );
      expect(
        engine.occurrencesBetween(sub, d(2026, 9, 1), d(2026, 9, 30)),
        isEmpty,
      );
    });
  });

  group('costs', () {
    Money yearly(BillingPeriod period, {int? customDays}) => engine.yearlyCost(
      subscriptionFixture(
        priceMinor: 1000,
        period: period,
        customDays: customDays,
      ),
    );

    test('yearly cost for every period', () {
      expect(yearly(BillingPeriod.weekly), const Money(52000, 'PKR'));
      expect(yearly(BillingPeriod.monthly), const Money(12000, 'PKR'));
      expect(yearly(BillingPeriod.quarterly), const Money(4000, 'PKR'));
      expect(yearly(BillingPeriod.yearly), const Money(1000, 'PKR'));
      expect(
        yearly(BillingPeriod.customDays, customDays: 45),
        const Money(8111, 'PKR'),
      );
    });

    test('monthly equivalent is a twelfth of the yearly cost', () {
      expect(
        engine.monthlyEquivalent(
          subscriptionFixture(priceMinor: 280000, period: BillingPeriod.yearly),
        ),
        const Money(23333, 'PKR'),
      );
    });
  });

  group('daysLeft and cycleProgress', () {
    final sub = subscriptionFixture(
      nextBillingDate: d(2026, 10, 1),
      startDate: d(2026, 9, 1),
    );

    test('daysLeft counts calendar days', () {
      expect(engine.daysLeft(sub, d(2026, 9, 19)), 12);
      expect(engine.daysLeft(sub, d(2026, 10, 1)), 0);
      expect(engine.daysLeft(sub, d(2026, 10, 3)), -2);
    });

    test('progress runs from 1 on renewal day to 0 on charge day', () {
      expect(engine.cycleProgress(sub, d(2026, 9, 1)), 1);
      expect(engine.cycleProgress(sub, d(2026, 9, 16)), closeTo(0.5, 0.001));
      expect(engine.cycleProgress(sub, d(2026, 10, 1)), 0);
      expect(engine.cycleProgress(sub, d(2026, 10, 5)), 0);
      expect(engine.cycleProgress(sub, d(2026, 8, 1)), 1);
    });

    test('a trial measures progress from its start date', () {
      final trial = subscriptionFixture(
        isTrial: true,
        startDate: d(2026, 9, 12),
        nextBillingDate: d(2026, 9, 19),
      );

      expect(engine.cycleProgress(trial, d(2026, 9, 12)), 1);
      expect(
        engine.cycleProgress(trial, d(2026, 9, 18)),
        closeTo(1 / 7, 0.001),
      );
    });

    test('a zero-length trial reports no progress left', () {
      final trial = subscriptionFixture(
        isTrial: true,
        startDate: d(2026, 9, 19),
        nextBillingDate: d(2026, 9, 19),
      );

      expect(engine.cycleProgress(trial, d(2026, 9, 19)), 0);
    });
  });
}
