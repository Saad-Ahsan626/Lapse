import 'package:lapse/features/reminders/data/notification_gateway.dart';
import 'package:lapse/features/reminders/domain/reminder_planner.dart';
import 'package:lapse/features/subscriptions/domain/repositories/subscription_repository.dart';

const snoozeDuration = Duration(hours: 24);

Future<void> snoozeSubscription({
  required String subscriptionId,
  required SubscriptionRepository repository,
  required NotificationGateway gateway,
  required ReminderPlanner planner,
  required int reminderMinutes,
  required DateTime now,
  int? notificationId,
}) async {
  if (notificationId != null) {
    await gateway.cancel(notificationId);
  }
  final subscription = await repository.getById(subscriptionId);
  if (subscription == null) return;
  final before = planner.planFor(
    subscription,
    reminderMinutes: reminderMinutes,
    now: now,
  );
  final snoozed = subscription.copyWith(
    snoozedUntil: now.toUtc().add(snoozeDuration),
    updatedAt: now.toUtc(),
  );
  await repository.upsert(snoozed);
  final after = planner.planFor(
    snoozed,
    reminderMinutes: reminderMinutes,
    now: now,
  );
  final keep = {for (final reminder in after) reminder.id};
  for (final reminder in before) {
    if (!keep.contains(reminder.id)) {
      await gateway.cancel(reminder.id);
    }
  }
  final exact = await gateway.canScheduleExact();
  for (final reminder in after) {
    if (!reminder.fireAt.isAfter(now)) continue;
    try {
      await gateway.schedule(reminder, exact: exact);
    } on Object {
      continue;
    }
  }
}
