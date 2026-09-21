import 'package:flutter_test/flutter_test.dart';
import 'package:lapse/core/domain/calendar_date.dart';
import 'package:lapse/core/domain/money.dart';
import 'package:lapse/features/subscriptions/domain/entities/billing_period.dart';
import 'package:lapse/features/subscriptions/domain/entities/charge.dart';
import 'package:lapse/features/subscriptions/domain/entities/subscription_status.dart';
import 'package:lapse/features/subscriptions/presentation/providers/home_providers.dart';
import 'package:lapse/features/subscriptions/presentation/providers/upcoming_charges.dart';

import '../../../../helpers/subscription_fixtures.dart';
import 'provider_test_support.dart';

void main() {
  late ProviderHarness harness;

  setUp(() => harness = ProviderHarness());
  tearDown(() => harness.dispose());

  Charge charge(String id, CalendarDate on, {int minor = 29900}) => Charge(
    id: id,
    subscriptionId: 'spotify',
    amount: Money(minor, 'PKR'),
    chargedOn: on,
  );

  void seedHome() {
    harness.repository
      ..seed([
        subscriptionFixture(
          id: 'spotify',
          name: 'Spotify',
          nextBillingDate: CalendarDate(2026, 9, 25),
        ),
        subscriptionFixture(
          id: 'netflix',
          name: 'Netflix',
          priceMinor: 110000,
          nextBillingDate: CalendarDate(2026, 9, 21),
        ),
        subscriptionFixture(
          id: 'icloud',
          name: 'iCloud',
          priceMinor: 25000,
          nextBillingDate: CalendarDate(2026, 10, 5),
        ),
        subscriptionFixture(
          id: 'trial-late',
          name: 'Duolingo',
          priceMinor: 64900,
          isTrial: true,
          nextBillingDate: CalendarDate(2026, 10, 2),
        ),
        subscriptionFixture(
          id: 'trial-soon',
          name: 'YouTube',
          priceMinor: 47900,
          isTrial: true,
          nextBillingDate: CalendarDate(2026, 9, 22),
        ),
        subscriptionFixture(
          id: 'gym',
          name: 'Gym',
          priceMinor: 500000,
          status: SubscriptionStatus.cancelled,
          nextBillingDate: CalendarDate(2026, 9, 20),
        ),
        subscriptionFixture(
          id: 'usd',
          name: 'ChatGPT',
          priceMinor: 2000,
          currency: 'USD',
          nextBillingDate: CalendarDate(2026, 9, 28),
        ),
      ])
      ..charges.addAll([
        charge('old', CalendarDate(2026, 8, 25)),
        charge('sep', CalendarDate(2026, 9, 3), minor: 1000),
      ]);
  }

  test('chargesThisMonth covers the whole current month', () async {
    seedHome();
    harness.repository.charges.add(charge('end', CalendarDate(2026, 9, 30)));

    final charges = await harness.read(chargesThisMonthProvider);

    expect(charges.map((c) => c.id), ['sep', 'end']);
  });

  test('spending summary for a seeded set', () async {
    seedHome();

    final summary = await harness.read(spendingSummaryProvider);

    expect(
      summary.thisMonth,
      const Money(1000 + 29900 + 110000 + 47900, 'PKR'),
    );
    expect(
      summary.yearly,
      const Money((29900 + 110000 + 25000 + 64900 + 47900) * 12, 'PKR'),
    );
    expect(summary.savedPerYear, const Money(500000 * 12, 'PKR'));
    expect(summary.otherCurrencies, {'USD': const Money(24000, 'USD')});
  });

  test('spending summary follows the default currency', () async {
    harness.dispose();
    harness = ProviderHarness(currency: 'USD');
    seedHome();

    final summary = await harness.read(spendingSummaryProvider);

    expect(summary.thisMonth, const Money(2000, 'USD'));
    expect(summary.yearly, const Money(24000, 'USD'));
    expect(summary.otherCurrencies.keys, ['PKR']);
  });

  test('spending summary updates after a change', () async {
    seedHome();
    final before = await harness.read(spendingSummaryProvider);

    await harness.repository.delete('netflix');
    await pumpEventQueue();
    final after = harness.container.read(spendingSummaryProvider).requireValue;

    expect(
      before.thisMonth.minor - after.thisMonth.minor,
      110000,
    );
  });

  test('upcoming lists this month, soonest first, without trials', () async {
    seedHome();

    final upcoming = await harness.read(upcomingChargesProvider);

    expect(upcoming.isThisMonth, isTrue);
    expect(upcoming.items.map((s) => s.id), ['netflix', 'spotify', 'usd']);
    expect(upcoming.isEmpty, isFalse);
  });

  test('upcoming falls back to the next three when none this month', () async {
    harness.repository.seed([
      for (var i = 1; i <= 5; i++)
        subscriptionFixture(
          id: 's$i',
          name: 'Sub $i',
          nextBillingDate: CalendarDate(2026, 10, 10 - i),
        ),
      subscriptionFixture(
        id: 'trial',
        isTrial: true,
        nextBillingDate: CalendarDate(2026, 9, 20),
      ),
    ]);

    final upcoming = await harness.read(upcomingChargesProvider);

    expect(upcoming.isThisMonth, isFalse);
    expect(upcoming.items.map((s) => s.id), ['s5', 's4', 's3']);
  });

  test('upcoming is empty with no active subscriptions', () async {
    harness.repository.seed([
      subscriptionFixture(status: SubscriptionStatus.cancelled),
    ]);

    final upcoming = await harness.read(upcomingChargesProvider);

    expect(upcoming.isEmpty, isTrue);
    expect(upcoming, const UpcomingCharges(items: [], isThisMonth: false));
  });

  test('overdue subscriptions stay in this month', () async {
    harness.repository.seed([
      subscriptionFixture(
        id: 'late',
        period: BillingPeriod.yearly,
        nextBillingDate: CalendarDate(2026, 9, 10),
      ),
    ]);

    final upcoming = await harness.read(upcomingChargesProvider);

    expect(upcoming.isThisMonth, isTrue);
    expect(upcoming.items.single.id, 'late');
  });

  test('trials ending are active trials, soonest first', () async {
    seedHome();
    harness.repository.seed([
      subscriptionFixture(
        id: 'trial-cancelled',
        isTrial: true,
        status: SubscriptionStatus.cancelled,
      ),
    ]);

    final trials = await harness.read(trialsEndingProvider);

    expect(trials.map((s) => s.id), ['trial-soon', 'trial-late']);
  });
}
