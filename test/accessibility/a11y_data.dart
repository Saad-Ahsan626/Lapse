import 'package:lapse/core/domain/calendar_date.dart';
import 'package:lapse/features/subscriptions/domain/entities/billing_period.dart';
import 'package:lapse/features/subscriptions/domain/entities/subscription.dart';
import 'package:lapse/features/subscriptions/domain/entities/subscription_status.dart';

import '../helpers/subscription_fixtures.dart';

List<Subscription> homeSubscriptions() => [
  subscriptionFixture(
    id: 'spotify',
    nextBillingDate: CalendarDate(2026, 9, 25),
  ),
  subscriptionFixture(
    id: 'chatgpt',
    name: 'ChatGPT Plus',
    priceMinor: 560000,
    nextBillingDate: CalendarDate(2026, 9, 19),
  ),
  subscriptionFixture(
    id: 'icloud',
    name: 'iCloud+ 200GB',
    priceMinor: 39000,
    period: BillingPeriod.yearly,
    nextBillingDate: CalendarDate(2026, 10, 24),
  ),
  subscriptionFixture(
    id: 'netflix',
    name: 'Netflix',
    priceMinor: 64900,
    isTrial: true,
    nextBillingDate: CalendarDate(2026, 9, 19),
  ),
  subscriptionFixture(
    id: 'canva',
    name: 'Canva Pro',
    priceMinor: 110000,
    status: SubscriptionStatus.cancelled,
    nextBillingDate: CalendarDate(2026, 9, 30),
  ),
];
