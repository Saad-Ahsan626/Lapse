import 'package:flutter/material.dart';
import 'package:lapse/core/domain/calendar_date.dart';
import 'package:lapse/features/subscriptions/domain/entities/subscription.dart';
import 'package:lapse/features/subscriptions/domain/entities/subscription_status.dart';

import '../features/subscriptions/presentation/widgets/detail/detail_test_support.dart';
import '../helpers/subscription_fixtures.dart';
import 'a11y_test_support.dart';

Map<String, Subscription> detailCases() => {
  'active': subscriptionFixture(
    name: 'ChatGPT Plus',
    nextBillingDate: CalendarDate(2026, 9, 21),
    cancelUrl: 'https://chatgpt.com/cancel',
  ),
  'trial': subscriptionFixture(
    name: 'Netflix',
    isTrial: true,
    nextBillingDate: CalendarDate(2026, 9, 19),
  ),
  'cancelled': subscriptionFixture(
    name: 'Hulu',
    status: SubscriptionStatus.cancelled,
  ).copyWith(cancelledAt: DateTime(2026, 9, 12, 12)),
};

void main() {
  for (final MapEntry(key: name, value: subscription)
      in detailCases().entries) {
    accessibilityTests('detail $name', (tester, brightness, scale) async {
      final harness = DetailHarness();
      harness.repository.seed([subscription]);
      await harness.pump(
        tester,
        brightness: brightness,
        textScale: scale,
        size: const Size(390, 844),
      );
    });
  }
}
