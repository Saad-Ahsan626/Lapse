import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lapse/core/platform/system_bridge_provider.dart';
import 'package:lapse/features/reminders/application/reminder_providers.dart';
import 'package:lapse/features/reminders/data/reminder_permission.dart';
import 'package:lapse/features/reminders/domain/planned_reminder.dart';
import 'package:lapse/features/settings/presentation/models/notification_health.dart';
import 'package:lapse/features/subscriptions/domain/entities/subscription.dart';
import 'package:lapse/features/subscriptions/presentation/providers/subscription_list_providers.dart';

final batteryOptimizationIgnoredProvider = FutureProvider<bool>(
  (ref) => ref.watch(systemBridgeProvider).isIgnoringBatteryOptimizations(),
);

final notificationHealthProvider = FutureProvider<NotificationHealth>((
  ref,
) async {
  final permission = ref.watch(notificationPermissionProvider.future);
  final exact = ref.watch(exactAlarmsAllowedProvider.future);
  final ignoring = ref.watch(batteryOptimizationIgnoredProvider.future);
  final pending = ref.watch(pendingReminderIdsProvider.future);
  final planned = ref.watch(plannedRemindersProvider).value ?? const [];
  final subscriptions = ref.watch(subscriptionsProvider).value ?? const [];

  final ids = await _or(pending, const <int>[]);
  return NotificationHealth(
    permission: await _or(permission, ReminderPermission.unknown),
    exactAlarms: await _or(exact, false),
    batteryOptimised: !await _or(ignoring, true),
    pendingCount: ids.length,
    next: nextPendingReminder(
      planned: planned,
      pendingIds: ids,
      subscriptions: subscriptions,
    ),
  );
});

NextReminder? nextPendingReminder({
  required List<PlannedReminder> planned,
  required List<int> pendingIds,
  required List<Subscription> subscriptions,
}) {
  final pending = pendingIds.toSet();
  PlannedReminder? first;
  for (final reminder in planned) {
    if (!pending.contains(reminder.id)) continue;
    if (first == null || reminder.fireAt.isBefore(first.fireAt)) {
      first = reminder;
    }
  }
  if (first == null) return null;
  final id = first.subscriptionId;
  final service = subscriptions
      .where((subscription) => subscription.id == id)
      .map((subscription) => subscription.name)
      .firstOrNull;
  return (service: service ?? first.title, fireAt: first.fireAt);
}

Future<void> refreshNotificationHealth(WidgetRef ref) async {
  ref
    ..invalidate(batteryOptimizationIgnoredProvider)
    ..invalidate(pendingReminderIdsProvider)
    ..invalidate(exactAlarmsAllowedProvider);
  try {
    await ref.read(notificationPermissionProvider.notifier).refresh();
  } on Object {
    return;
  }
}

Future<T> _or<T>(Future<T> future, T fallback) async {
  try {
    return await future;
  } on Object {
    return fallback;
  }
}
