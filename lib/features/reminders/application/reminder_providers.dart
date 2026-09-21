import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lapse/app/router/app_router.dart';
import 'package:lapse/core/providers/clock_providers.dart';
import 'package:lapse/features/reminders/application/background_notification_handler.dart';
import 'package:lapse/features/reminders/application/notification_permission_controller.dart';
import 'package:lapse/features/reminders/application/notification_tap_handler.dart';
import 'package:lapse/features/reminders/application/reminder_sync_controller.dart';
import 'package:lapse/features/reminders/application/reminder_sync_result.dart';
import 'package:lapse/features/reminders/application/snooze_subscription.dart';
import 'package:lapse/features/reminders/data/local_notification_gateway.dart';
import 'package:lapse/features/reminders/data/local_timezone.dart';
import 'package:lapse/features/reminders/data/notification_gateway.dart';
import 'package:lapse/features/reminders/data/reminder_permission.dart';
import 'package:lapse/features/reminders/domain/planned_reminder.dart';
import 'package:lapse/features/reminders/domain/reminder_planner.dart';
import 'package:lapse/features/settings/presentation/providers/settings_providers.dart';
import 'package:lapse/features/subscriptions/presentation/providers/link_opener_provider.dart';
import 'package:lapse/features/subscriptions/presentation/providers/subscription_list_providers.dart';
import 'package:lapse/features/subscriptions/presentation/providers/subscription_service_providers.dart';

final notificationGatewayProvider = Provider<NotificationGateway>(
  (ref) => LocalNotificationGateway(
    onBackgroundResponse: onBackgroundNotificationResponse,
  ),
);

final reminderPlannerProvider = Provider<ReminderPlanner>(
  (ref) => const ReminderPlanner(),
);

final configureTimezoneProvider = Provider<Future<String> Function()>(
  (ref) => configureLocalTimezone,
);

final notificationPermissionProvider =
    AsyncNotifierProvider<NotificationPermissionController, ReminderPermission>(
      NotificationPermissionController.new,
    );

final exactAlarmsAllowedProvider = FutureProvider<bool>(
  (ref) => ref.watch(notificationGatewayProvider).canScheduleExact(),
);

final plannedRemindersProvider = Provider<AsyncValue<List<PlannedReminder>>>((
  ref,
) {
  final planner = ref.watch(reminderPlannerProvider);
  final minutes = ref.watch(
    settingsProvider.select((settings) => settings.reminderMinutes),
  );
  final clock = ref.watch(clockProvider);
  return ref
      .watch(subscriptionsProvider)
      .whenData(
        (subscriptions) => planner.plan(
          subscriptions: subscriptions,
          reminderMinutes: minutes,
          now: clock(),
        ),
      );
});

final pendingReminderIdsProvider = FutureProvider<List<int>>(
  (ref) => ref.watch(notificationGatewayProvider).pendingIds(),
);

final reminderSyncProvider =
    NotifierProvider<ReminderSyncController, ReminderSyncResult?>(
      ReminderSyncController.new,
    );

final notificationTapHandlerProvider = Provider<NotificationTapHandler>(
  (ref) => NotificationTapHandler(
    router: ref.watch(appRouterProvider),
    repository: ref.watch(subscriptionRepositoryProvider),
    linkOpener: ref.watch(linkOpenerProvider),
    snooze: (subscriptionId) => snoozeSubscription(
      subscriptionId: subscriptionId,
      repository: ref.read(subscriptionRepositoryProvider),
      gateway: ref.read(notificationGatewayProvider),
      planner: ref.read(reminderPlannerProvider),
      reminderMinutes: ref.read(settingsProvider).reminderMinutes,
      now: ref.read(clockProvider)(),
    ),
  ),
);
