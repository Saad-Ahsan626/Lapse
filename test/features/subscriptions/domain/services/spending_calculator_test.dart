import 'package:flutter_test/flutter_test.dart';
import 'package:lapse/core/domain/calendar_date.dart';
import 'package:lapse/core/domain/money.dart';
import 'package:lapse/features/subscriptions/domain/entities/billing_period.dart';
import 'package:lapse/features/subscriptions/domain/entities/charge.dart';
import 'package:lapse/features/subscriptions/domain/entities/subscription.dart';
import 'package:lapse/features/subscriptions/domain/entities/subscription_status.dart';
import 'package:lapse/features/subscriptions/domain/services/billing_engine.dart';
import 'package:lapse/features/subscriptions/domain/services/spending_calculator.dart';
import 'package:lapse/features/subscriptions/domain/services/spending_summary.dart';

import '../../../../helpers/subscription_fixtures.dart';
import '../../../../helpers/test_clock.dart';

void main() {
  const engine = BillingEngine();
  const calculator = SpendingCalculator(engine);
  final today = CalendarDate(2026, 9, 19);

  SpendingSummary summarize(
    List<Subscription> subscriptions, {
    List<Charge> charges = const [],
    CalendarDate? on,
    String currency = 'PKR',
  }) => calculator.summarize(
    subscriptions: subscriptions,
    chargesThisMonth: charges,
    today: on ?? today,
    currency: currency,
  );

  Charge charge(
    CalendarDate on, {
    int minor = 29900,
    String currency = 'PKR',
    String sub = 'gone',
  }) => Charge(
    id: 'c-$on-$sub',
    subscriptionId: sub,
    amount: Money(minor, currency),
    chargedOn: on,
  );

  Money pkr(int minor) => Money(minor, 'PKR');

  test('empty input gives zeros in the default currency', () {
    final summary = summarize(const []);

    expect(summary, SpendingSummary.zero('PKR'));
    expect(summary.hasSavings, isFalse);
    expect(summary.otherCurrencies, isEmpty);
  });

  test('monthly sub due later this month counts once, yearly ×12', () {
    final summary = summarize([
      subscriptionFixture(nextBillingDate: CalendarDate(2026, 9, 25)),
    ]);

    expect(summary.thisMonth, pkr(29900));
    expect(summary.yearly, pkr(29900 * 12));
    expect(summary.savedPerYear, pkr(0));
  });

  test('a charge due on the last day counts, the 1st of next does not', () {
    final summary = summarize([
      subscriptionFixture(id: 'a', nextBillingDate: CalendarDate(2026, 9, 30)),
      subscriptionFixture(id: 'b', nextBillingDate: CalendarDate(2026, 10, 1)),
    ]);

    expect(summary.thisMonth, pkr(29900));
    expect(summary.yearly, pkr(29900 * 24));
  });

  test('logged charges on the 1st and last day of the month are summed', () {
    final summary = summarize(
      const [],
      charges: [
        charge(CalendarDate(2026, 9, 1)),
        charge(CalendarDate(2026, 9, 30), minor: 100),
      ],
      on: CalendarDate(2026, 9, 30),
    );

    expect(summary.thisMonth, pkr(30000));
  });

  test('logged charges outside the month are ignored', () {
    final summary = summarize(
      const [],
      charges: [
        charge(CalendarDate(2026, 8, 31)),
        charge(CalendarDate(2026, 10, 1)),
      ],
    );

    expect(summary.thisMonth, pkr(0));
  });

  test('upcoming from the 1st includes a charge due on the 1st', () {
    final summary = summarize(
      [subscriptionFixture(nextBillingDate: CalendarDate(2026, 9, 1))],
      on: CalendarDate(2026, 9, 1),
    );

    expect(summary.thisMonth, pkr(29900));
  });

  test('a charge due today is counted once, before and after roll-over', () {
    final due = subscriptionFixture(nextBillingDate: today);
    final before = summarize([due]);

    final tomorrow = today.addDays(1);
    final rolled = engine.rollOver(due, tomorrow, newId: SequentialIds().call);
    final after = summarize(
      [rolled.subscription],
      charges: rolled.charges,
      on: tomorrow,
    );

    expect(rolled.charges.single.chargedOn, today);
    expect(before.thisMonth, pkr(29900));
    expect(after.thisMonth, pkr(29900));
  });

  test('a weekly sub counts every charge in the month', () {
    final weekly = subscriptionFixture(
      priceMinor: 1000,
      period: BillingPeriod.weekly,
      nextBillingDate: today,
    );

    final summary = summarize(
      [weekly],
      charges: [
        charge(CalendarDate(2026, 9, 5), minor: 1000, sub: weekly.id),
        charge(CalendarDate(2026, 9, 12), minor: 1000, sub: weekly.id),
      ],
    );

    expect(summary.thisMonth, pkr(4000));
    expect(summary.yearly, pkr(52000));
  });

  test('a weekly sub from the 1st charges five times in September', () {
    final summary = summarize(
      [
        subscriptionFixture(
          priceMinor: 1000,
          period: BillingPeriod.weekly,
          nextBillingDate: CalendarDate(2026, 9, 1),
        ),
      ],
      on: CalendarDate(2026, 9, 1),
    );

    expect(summary.thisMonth, pkr(5000));
  });

  test('trials count at their after-trial price', () {
    final summary = summarize([
      subscriptionFixture(
        priceMinor: 64900,
        isTrial: true,
        nextBillingDate: CalendarDate(2026, 9, 22),
      ),
    ]);

    expect(summary.thisMonth, pkr(64900));
    expect(summary.yearly, pkr(64900 * 12));
  });

  test('cancelled subs only count as savings', () {
    final summary = summarize([
      subscriptionFixture(
        status: SubscriptionStatus.cancelled,
        nextBillingDate: CalendarDate(2026, 9, 25),
      ),
      subscriptionFixture(
        id: 'yearly',
        priceMinor: 100000,
        period: BillingPeriod.yearly,
        status: SubscriptionStatus.cancelled,
      ),
    ]);

    expect(summary.thisMonth, pkr(0));
    expect(summary.yearly, pkr(0));
    expect(summary.savedPerYear, pkr(29900 * 12 + 100000));
    expect(summary.hasSavings, isTrue);
  });

  test('other currencies are kept apart as yearly totals', () {
    final summary = summarize(
      [
        subscriptionFixture(nextBillingDate: CalendarDate(2026, 9, 25)),
        subscriptionFixture(
          id: 'usd-1',
          priceMinor: 1299,
          currency: 'USD',
          nextBillingDate: CalendarDate(2026, 9, 20),
        ),
        subscriptionFixture(
          id: 'usd-2',
          priceMinor: 1000,
          currency: 'USD',
          period: BillingPeriod.yearly,
        ),
        subscriptionFixture(
          id: 'eur',
          priceMinor: 500,
          currency: 'EUR',
          status: SubscriptionStatus.cancelled,
        ),
      ],
      charges: [charge(CalendarDate(2026, 9, 3), currency: 'USD')],
    );

    expect(summary.thisMonth, pkr(29900));
    expect(summary.yearly, pkr(29900 * 12));
    expect(summary.savedPerYear, pkr(0));
    expect(summary.otherCurrencies, {
      'USD': const Money(1299 * 12 + 1000, 'USD'),
    });
  });

  test('quarterly and custom periods use the engine yearly cost', () {
    final summary = summarize([
      subscriptionFixture(
        id: 'q',
        priceMinor: 1000,
        period: BillingPeriod.quarterly,
        nextBillingDate: CalendarDate(2026, 12, 1),
      ),
      subscriptionFixture(
        id: 'c',
        priceMinor: 1000,
        period: BillingPeriod.customDays,
        customDays: 73,
        nextBillingDate: CalendarDate(2026, 12, 1),
      ),
    ]);

    expect(summary.thisMonth, pkr(0));
    expect(summary.yearly, pkr(4000 + 5000));
  });

  test('summary value semantics', () {
    final a = SpendingSummary(
      thisMonth: pkr(1),
      yearly: pkr(2),
      savedPerYear: pkr(3),
      otherCurrencies: const {'USD': Money(4, 'USD')},
    );
    final b = SpendingSummary(
      thisMonth: pkr(1),
      yearly: pkr(2),
      savedPerYear: pkr(3),
      otherCurrencies: const {'USD': Money(4, 'USD')},
    );

    expect(a, b);
    expect(a.hashCode, b.hashCode);
    expect(a, isNot(SpendingSummary.zero('PKR')));
    expect(a.toString(), contains('SpendingSummary'));
  });
}
