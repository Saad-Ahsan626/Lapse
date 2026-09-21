import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:lapse/core/database/app_database.dart';
import 'package:lapse/features/reminders/application/snooze_subscription.dart';
import 'package:lapse/features/reminders/data/local_notification_gateway.dart';
import 'package:lapse/features/reminders/data/local_timezone.dart';
import 'package:lapse/features/reminders/data/notification_tap.dart';
import 'package:lapse/features/reminders/domain/reminder_planner.dart';
import 'package:lapse/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:lapse/features/settings/domain/entities/app_settings.dart';
import 'package:lapse/features/subscriptions/data/repositories/subscription_repository_impl.dart';
import 'package:shared_preferences/shared_preferences.dart';

@pragma('vm:entry-point')
Future<void> onBackgroundNotificationResponse(
  NotificationResponse response,
) async {
  final tap = NotificationTap.fromResponse(response);
  if (tap == null || tap.action != NotificationAction.snooze) return;
  WidgetsFlutterBinding.ensureInitialized();
  await configureLocalTimezone();
  final database = await openAppDatabase();
  final repository = SubscriptionRepositoryImpl(database);
  try {
    await snoozeSubscription(
      subscriptionId: tap.subscriptionId,
      repository: repository,
      gateway: LocalNotificationGateway(),
      planner: const ReminderPlanner(),
      reminderMinutes: await _reminderMinutes(),
      now: DateTime.now(),
      notificationId: response.id,
    );
  } finally {
    await repository.dispose();
    await database.close();
  }
}

Future<int> _reminderMinutes() async {
  try {
    final preferences = await SharedPreferencesWithCache.create(
      cacheOptions: const SharedPreferencesWithCacheOptions(
        allowList: SettingsRepositoryImpl.allKeys,
      ),
    );
    return SettingsRepositoryImpl(
      preferences,
      fallbackCurrency: 'USD',
    ).load().reminderMinutes;
  } on Object {
    return AppSettings.defaultReminderMinutes;
  }
}
