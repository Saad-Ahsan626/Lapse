import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lapse/core/domain/calendar_date.dart';
import 'package:lapse/core/domain/money.dart';
import 'package:lapse/core/domain/urgency.dart';
import 'package:lapse/features/subscriptions/domain/entities/charge.dart';
import 'package:lapse/features/subscriptions/domain/entities/subscription_status.dart';
import 'package:lapse/features/subscriptions/presentation/providers/subscription_detail.dart';
import 'package:lapse/features/subscriptions/presentation/providers/subscription_detail_providers.dart';

import '../../../../helpers/subscription_fixtures.dart';
import 'provider_test_support.dart';

void main() {
  late ProviderHarness harness;
  final today = CalendarDate(2026, 9, 19);

  setUp(() => harness = ProviderHarness());
  tearDown(() => harness.dispose());

  Future<SubscriptionDetail?> detailFor(String id) =>
      harness.read(subscriptionDetailProvider(id));

  Charge charge(String id, int day, {String currency = 'PKR'}) => Charge(
    id: id,
    subscriptionId: 'sub-1',
    amount: Money(29900, currency),
    chargedOn: CalendarDate(2026, 8, day),
  );

  test('upcoming subscription with its payment history', () async {
    harness.repository
      ..seed([
        subscriptionFixture(
          nextBillingDate: today.addDays(6),
          startDate: CalendarDate(2026, 7, 25),
        ),
      ])
      ..charges.addAll([charge('a', 1), charge('b', 25)]);

    final detail = (await detailFor('sub-1'))!;

    expect(detail.ringState, DetailRingState.upcoming);
    expect(detail.daysLeft, 6);
    expect(detail.urgency, Urgency.normal);
    expect(detail.totalPaid, const Money(59800, 'PKR'));
    expect(detail.chargeCount, 2);
    expect(detail.progress, closeTo(6 / 31, 0.0001));
    expect(detail.subscription.id, 'sub-1');
  });

  test(
    'total paid is zero without charges and skips other currencies',
    () async {
      harness.repository
        ..seed([subscriptionFixture(nextBillingDate: today.addDays(2))])
        ..charges.add(charge('usd', 3, currency: 'USD'));

      final detail = (await detailFor('sub-1'))!;

      expect(detail.totalPaid, const Money.zero('PKR'));
      expect(detail.chargeCount, 1);
      expect(detail.urgency, Urgency.warning);
    },
  );

  test('due today', () async {
    harness.repository.seed([subscriptionFixture(nextBillingDate: today)]);

    final detail = (await detailFor('sub-1'))!;

    expect(detail.ringState, DetailRingState.today);
    expect(detail.daysLeft, 0);
    expect(detail.urgency, Urgency.urgent);
  });

  test('overdue before roll-over', () async {
    harness.repository.seed([
      subscriptionFixture(nextBillingDate: today.addDays(-2)),
    ]);

    final detail = (await detailFor('sub-1'))!;

    expect(detail.ringState, DetailRingState.overdue);
    expect(detail.daysLeft, -2);
    expect(detail.progress, 0);
  });

  test('cancelled wins over the date', () async {
    harness.repository.seed([
      subscriptionFixture(
        nextBillingDate: today,
        status: SubscriptionStatus.cancelled,
      ),
    ]);

    final detail = (await detailFor('sub-1'))!;

    expect(detail.ringState, DetailRingState.cancelled);
  });

  test('missing or deleted subscriptions give null', () async {
    harness.repository.seed([subscriptionFixture()]);

    expect(await detailFor('missing'), isNull);
    expect(await detailFor('sub-1'), isNotNull);

    await harness.repository.delete('sub-1');
    await pumpEventQueue();

    final value = harness.container.read(subscriptionDetailProvider('sub-1'));
    expect(value.hasValue, isTrue);
    expect(value.value, isNull);
  });

  test('detail value semantics', () {
    SubscriptionDetail make(int days) => SubscriptionDetail(
      subscription: subscriptionFixture(),
      totalPaid: const Money.zero('PKR'),
      chargeCount: 0,
      daysLeft: days,
      urgency: Urgency.normal,
      progress: 0.5,
      ringState: DetailRingState.upcoming,
    );

    expect(make(5), make(5));
    expect(make(5).hashCode, make(5).hashCode);
    expect(make(5), isNot(make(6)));
    expect(make(5).toString(), contains('upcoming'));
  });
}
