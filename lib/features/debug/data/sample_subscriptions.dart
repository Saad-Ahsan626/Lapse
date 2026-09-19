import 'package:lapse/core/domain/calendar_date.dart';
import 'package:lapse/core/domain/money.dart';
import 'package:lapse/features/subscriptions/domain/entities/billing_period.dart';
import 'package:lapse/features/subscriptions/domain/entities/subscription.dart';

const sampleCancelledName = 'YouTube Premium';

List<Subscription> sampleSubscriptions(CalendarDate today, String currency) {
  final now = DateTime.now().toUtc();

  Subscription draft({
    required String name,
    required int price,
    required BillingPeriod period,
    required int startOffset,
    required int nextOffset,
    String? category,
    String? cancelUrl,
    int? customDays,
    bool isTrial = false,
  }) {
    final next = today.addDays(nextOffset);
    return Subscription(
      id: Subscription.unsavedId,
      name: name,
      category: category,
      price: Money(price * 100, currency),
      period: period,
      customDays: customDays,
      anchorDay: next.day,
      startDate: today.addDays(startOffset),
      nextBillingDate: next,
      isTrial: isTrial,
      reminderOffsets: const [7, 1],
      cancelUrl: cancelUrl,
      createdAt: now,
      updatedAt: now,
    );
  }

  return [
    draft(
      name: 'Spotify Premium',
      price: 299,
      period: BillingPeriod.monthly,
      startOffset: -29,
      nextOffset: 1,
      category: 'Music',
      cancelUrl: 'https://www.spotify.com/account/subscription/',
    ),
    draft(
      name: 'Netflix',
      price: 649,
      period: BillingPeriod.monthly,
      startOffset: -4,
      nextOffset: 3,
      category: 'Entertainment',
      cancelUrl: 'https://www.netflix.com/cancelplan',
      isTrial: true,
    ),
    draft(
      name: 'ChatGPT Plus',
      price: 5600,
      period: BillingPeriod.monthly,
      startOffset: -27,
      nextOffset: 3,
      category: 'Productivity',
    ),
    draft(
      name: 'iCloud+ 200GB',
      price: 390,
      period: BillingPeriod.monthly,
      startOffset: -10,
      nextOffset: 20,
      category: 'Storage',
    ),
    draft(
      name: 'Notion Plus',
      price: 2800,
      period: BillingPeriod.yearly,
      startOffset: -215,
      nextOffset: 150,
      category: 'Productivity',
    ),
    draft(
      name: 'Gym membership',
      price: 4500,
      period: BillingPeriod.customDays,
      customDays: 45,
      startOffset: -33,
      nextOffset: 12,
      category: 'Health',
    ),
    draft(
      name: 'Canva Pro',
      price: 1100,
      period: BillingPeriod.monthly,
      startOffset: -100,
      nextOffset: -40,
      category: 'Design',
    ),
    draft(
      name: sampleCancelledName,
      price: 479,
      period: BillingPeriod.monthly,
      startOffset: -20,
      nextOffset: 10,
      category: 'Entertainment',
    ),
  ];
}
