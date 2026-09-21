import 'package:lapse/core/domain/calendar_date.dart';
import 'package:lapse/core/domain/money.dart';
import 'package:lapse/features/backup/domain/backup_data.dart';
import 'package:lapse/features/backup/domain/backup_settings.dart';
import 'package:lapse/features/settings/domain/entities/app_theme_mode.dart';
import 'package:lapse/features/subscriptions/domain/entities/billing_period.dart';
import 'package:lapse/features/subscriptions/domain/entities/charge.dart';
import 'package:lapse/features/subscriptions/domain/entities/subscription.dart';
import 'package:lapse/features/subscriptions/domain/entities/subscription_status.dart';

import '../../helpers/subscription_fixtures.dart';

final backupExportedAt = DateTime.utc(2026, 9, 21, 6, 30, 15, 123);

Subscription fullSubscription() => Subscription(
  id: 'sub-full',
  name: 'Netflix Standard',
  catalogKey: 'netflix',
  category: 'Streaming',
  price: const Money(155000, 'PKR'),
  period: BillingPeriod.monthly,
  anchorDay: 31,
  startDate: CalendarDate(2025, 1, 31),
  nextBillingDate: CalendarDate(2026, 9, 30),
  reminderOffsets: const [7, 3, 1, 0],
  cancelUrl: 'https://www.netflix.com/cancelplan',
  paymentMethod: 'Visa •• 4242',
  notes: 'Shared with "family"\nsecond line',
  snoozedUntil: DateTime.utc(2026, 9, 28, 4),
  createdAt: DateTime.utc(2025, 1, 31, 9, 15, 0, 1, 2),
  updatedAt: DateTime.utc(2026, 9, 2, 18),
);

Subscription customTrial() => subscriptionFixture(
  id: 'sub-trial',
  name: 'Gym',
  priceMinor: 500000,
  period: BillingPeriod.customDays,
  customDays: 45,
  isTrial: true,
  reminderOffsets: const [],
);

Subscription cancelledYearly() => subscriptionFixture(
  id: 'sub-cancelled',
  name: 'Adobe',
  priceMinor: 2000,
  currency: 'USD',
  period: BillingPeriod.yearly,
  status: SubscriptionStatus.cancelled,
).copyWith(cancelledAt: DateTime.utc(2026, 8, 15, 12));

Subscription quarterlyYen() => subscriptionFixture(
  id: 'sub-yen',
  name: 'Crunchyroll',
  priceMinor: 1500,
  currency: 'JPY',
  period: BillingPeriod.quarterly,
);

Subscription weeklyBare() => subscriptionFixture(
  id: 'sub-weekly',
  name: 'Paper',
  priceMinor: 20000,
  period: BillingPeriod.weekly,
);

Charge chargeFixture(
  String id, {
  String subscriptionId = 'sub-full',
  int minor = 155000,
  String currency = 'PKR',
  CalendarDate? on,
}) => Charge(
  id: id,
  subscriptionId: subscriptionId,
  amount: Money(minor, currency),
  chargedOn: on ?? CalendarDate(2026, 8, 31),
);

BackupSettings settingsFixture({String? userName = 'Saad'}) => BackupSettings(
  defaultCurrency: 'USD',
  reminderMinutes: 20 * 60 + 30,
  defaultReminderOffsets: const [3, 0],
  themeMode: AppThemeMode.dark,
  userName: userName,
);

BackupData fullBackup() => BackupData(
  exportedAt: backupExportedAt,
  settings: settingsFixture(),
  subscriptions: [
    fullSubscription(),
    customTrial(),
    cancelledYearly(),
    quarterlyYen(),
    weeklyBare(),
  ],
  charges: [
    chargeFixture('c-1', on: CalendarDate(2026, 7, 31)),
    chargeFixture('c-2'),
    chargeFixture(
      'c-3',
      subscriptionId: 'sub-cancelled',
      minor: 2000,
      currency: 'USD',
      on: CalendarDate(2025, 9, 1),
    ),
  ],
);
