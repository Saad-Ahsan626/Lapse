import 'package:flutter_test/flutter_test.dart';
import 'package:lapse/core/domain/calendar_date.dart';
import 'package:lapse/features/subscriptions/domain/entities/billing_period.dart';
import 'package:lapse/features/subscriptions/domain/entities/subscription_status.dart';
import 'package:lapse/features/subscriptions/presentation/providers/subscription_sort.dart';
import 'package:lapse/features/subscriptions/presentation/providers/subscription_tab.dart';
import 'package:lapse/features/subscriptions/presentation/providers/subscription_tab_providers.dart';
import 'package:lapse/features/subscriptions/presentation/providers/tab_counts.dart';

import '../../../../helpers/subscription_fixtures.dart';
import 'provider_test_support.dart';

void main() {
  late ProviderHarness harness;

  setUp(() {
    harness = ProviderHarness();
    harness.repository.seed([
      subscriptionFixture(
        id: 'b',
        name: 'bumble',
        priceMinor: 100000,
        period: BillingPeriod.yearly,
        nextBillingDate: CalendarDate(2026, 9, 21),
      ),
      subscriptionFixture(
        id: 'a',
        name: 'Apple Music',
        priceMinor: 30000,
        nextBillingDate: CalendarDate(2026, 10, 3),
      ),
      subscriptionFixture(
        id: 'c',
        name: 'Canva',
        priceMinor: 30000,
        nextBillingDate: CalendarDate(2026, 9, 21),
      ),
      subscriptionFixture(
        id: 't1',
        name: 'Zoom',
        isTrial: true,
        nextBillingDate: CalendarDate(2026, 9, 25),
      ),
      subscriptionFixture(
        id: 't2',
        name: 'Figma',
        isTrial: true,
        nextBillingDate: CalendarDate(2026, 9, 29),
      ),
      subscriptionFixture(
        id: 'x1',
        name: 'Hulu',
        status: SubscriptionStatus.cancelled,
      ).copyWith(cancelledAt: DateTime.utc(2026, 9, 2)),
      subscriptionFixture(
        id: 'x2',
        name: 'Disney',
        priceMinor: 90000,
        status: SubscriptionStatus.cancelled,
      ).copyWith(cancelledAt: DateTime.utc(2026, 9, 15)),
    ]);
  });
  tearDown(() => harness.dispose());

  Future<List<String>> ids(SubscriptionTab tab) async => (await harness.read(
    subscriptionTabProvider(tab),
  )).map((s) => s.id).toList();

  void sortBy(SubscriptionSort sort) =>
      harness.container.read(subscriptionSortProvider.notifier).select(sort);

  test('tab from query and sort labels', () {
    expect(SubscriptionTab.fromQuery('trials'), SubscriptionTab.trials);
    expect(SubscriptionTab.fromQuery('cancelled'), SubscriptionTab.cancelled);
    expect(SubscriptionTab.fromQuery('active'), SubscriptionTab.active);
    expect(SubscriptionTab.fromQuery(null), SubscriptionTab.active);
    expect(SubscriptionTab.fromQuery('nonsense'), SubscriptionTab.active);
    expect(SubscriptionSort.values.map((s) => s.label), [
      'Next charge',
      'Price',
      'Name',
    ]);
  });

  test('counts split active, trials and cancelled', () async {
    final counts = await harness.read(subscriptionTabCountsProvider);

    expect(counts, const TabCounts(active: 3, trials: 2, cancelled: 2));
    expect(counts.total, 7);
    expect(counts.of(SubscriptionTab.trials), 2);
    expect(TabCounts.empty.total, 0);
  });

  test('default sort is next charge, ties by name', () async {
    expect(
      harness.container.read(subscriptionSortProvider),
      SubscriptionSort.nextCharge,
    );
    expect(await ids(SubscriptionTab.active), ['b', 'c', 'a']);
    expect(await ids(SubscriptionTab.trials), ['t1', 't2']);
  });

  test('cancelled tab shows most recently cancelled first', () async {
    expect(await ids(SubscriptionTab.cancelled), ['x2', 'x1']);
  });

  test('price sort is by yearly cost, high to low', () async {
    sortBy(SubscriptionSort.price);

    expect(await ids(SubscriptionTab.active), ['a', 'c', 'b']);
    expect(await ids(SubscriptionTab.cancelled), ['x2', 'x1']);
  });

  test('name sort is case-insensitive A–Z', () async {
    sortBy(SubscriptionSort.name);

    expect(await ids(SubscriptionTab.active), ['a', 'b', 'c']);
    expect(await ids(SubscriptionTab.trials), ['t2', 't1']);
    expect(await ids(SubscriptionTab.cancelled), ['x2', 'x1']);
  });

  test('selecting the same sort keeps the state', () {
    final notifier = harness.container.read(subscriptionSortProvider.notifier);
    var changes = 0;
    harness.container.listen(subscriptionSortProvider, (_, _) => changes++);

    notifier
      ..select(SubscriptionSort.nextCharge)
      ..select(SubscriptionSort.name)
      ..select(SubscriptionSort.name);

    expect(changes, 1);
  });
}
