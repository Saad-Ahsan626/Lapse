import 'package:lapse/core/domain/clock.dart';
import 'package:lapse/features/reminders/application/reminder_sync_result.dart';
import 'package:lapse/features/reminders/data/notification_gateway.dart';
import 'package:lapse/features/reminders/domain/reminder_planner.dart';
import 'package:lapse/features/subscriptions/domain/entities/subscription.dart';

class ReminderSync {
  const ReminderSync({
    required NotificationGateway gateway,
    required ReminderPlanner planner,
    Clock? clock,
  }) : _gateway = gateway,
       _planner = planner,
       _clock = clock;

  final NotificationGateway _gateway;
  final ReminderPlanner _planner;
  final Clock? _clock;

  Future<ReminderSyncResult> sync({
    required List<Subscription> subscriptions,
    required int reminderMinutes,
    required DateTime now,
  }) async {
    final plan = _planner.plan(
      subscriptions: subscriptions,
      reminderMinutes: reminderMinutes,
      now: now,
    );
    await _gateway.cancelAll();
    final exact = await _gateway.canScheduleExact();
    var scheduled = 0;
    for (final reminder in plan) {
      final current = _clock?.call() ?? now;
      if (!reminder.fireAt.isAfter(current)) continue;
      try {
        await _gateway.schedule(reminder, exact: exact);
        scheduled++;
      } on Object {
        continue;
      }
    }
    return ReminderSyncResult(
      scheduled: scheduled,
      exact: exact,
      syncedAt: _clock?.call() ?? now,
    );
  }
}
