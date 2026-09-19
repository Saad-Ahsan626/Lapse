import 'package:lapse/core/domain/calendar_date.dart';
import 'package:lapse/core/domain/money.dart';
import 'package:lapse/features/subscriptions/domain/entities/billing_period.dart';
import 'package:lapse/features/subscriptions/domain/entities/subscription.dart';
import 'package:lapse/features/subscriptions/domain/entities/subscription_status.dart';

final fixtureTimestamp = DateTime.utc(2026, 9, 1, 8);

Subscription subscriptionFixture({
  String id = 'sub-1',
  String name = 'Spotify Premium',
  int priceMinor = 29900,
  String currency = 'PKR',
  BillingPeriod period = BillingPeriod.monthly,
  int? customDays,
  int? anchorDay,
  CalendarDate? startDate,
  CalendarDate? nextBillingDate,
  bool isTrial = false,
  List<int> reminderOffsets = const [7, 1],
  String? cancelUrl,
  SubscriptionStatus status = SubscriptionStatus.active,
}) {
  final next = nextBillingDate ?? CalendarDate(2026, 10, 1);
  return Subscription(
    id: id,
    name: name,
    price: Money(priceMinor, currency),
    period: period,
    customDays: customDays,
    anchorDay: anchorDay ?? next.day,
    startDate: startDate ?? CalendarDate(2026, 9, 1),
    nextBillingDate: next,
    isTrial: isTrial,
    reminderOffsets: reminderOffsets,
    cancelUrl: cancelUrl,
    status: status,
    createdAt: fixtureTimestamp,
    updatedAt: fixtureTimestamp,
  );
}
