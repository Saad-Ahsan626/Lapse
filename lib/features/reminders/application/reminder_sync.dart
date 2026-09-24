import 'package:lapse/core/domain/clock.dart';
import 'package:lapse/features/reminders/application/reminder_sync_result.dart';
import 'package:lapse/features/reminders/data/memory_reminder_plan_store.dart';
import 'package:lapse/features/reminders/data/notification_gateway.dart';
import 'package:lapse/features/reminders/data/reminder_plan_store.dart';
import 'package:lapse/features/reminders/domain/planned_reminder.dart';
import 'package:lapse/features/reminders/domain/reminder_planner.dart';
import 'package:lapse/features/reminders/domain/reminder_signature.dart';
import 'package:lapse/features/subscriptions/domain/entities/subscription.dart';

class ReminderSync {
  ReminderSync({
    required NotificationGateway gateway,
    required ReminderPlanner planner,
    ReminderPlanStore? planStore,
    Clock? clock,
  }) : _gateway = gateway,
       _planner = planner,
       _store = planStore ?? MemoryReminderPlanStore(),
       _clock = clock;

  final NotificationGateway _gateway;
  final ReminderPlanner _planner;
  final ReminderPlanStore _store;
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
    final exact = await _gateway.canScheduleExact();
    final startedAt = _now(now);
    final desired = <int, PlannedReminder>{
      for (final reminder in plan)
        if (reminder.fireAt.isAfter(startedAt)) reminder.id: reminder,
    };
    final stored = await _loadStored();
    final live = await _pendingIds() ?? stored.keys.toSet();

    final applied = <int, String>{};
    final toCancel = <int>[
      for (final id in live)
        if (!desired.containsKey(id)) id,
    ];
    final toSchedule = <PlannedReminder>[];
    for (final reminder in desired.values) {
      final signature = reminderSignature(reminder, exact: exact);
      if (live.contains(reminder.id)) {
        final previous = stored[reminder.id];
        if (previous == signature) {
          applied[reminder.id] = signature;
          continue;
        }
        if (previous != null) toCancel.add(reminder.id);
      }
      toSchedule.add(reminder);
    }

    for (final id in toCancel) {
      try {
        await _gateway.cancel(id);
      } on Object {
        continue;
      }
    }
    for (final reminder in toSchedule) {
      if (!reminder.fireAt.isAfter(_now(now))) continue;
      try {
        await _gateway.schedule(reminder, exact: exact);
        applied[reminder.id] = reminderSignature(reminder, exact: exact);
      } on Object {
        continue;
      }
    }

    if (toCancel.isNotEmpty ||
        toSchedule.isNotEmpty ||
        !_sameKeys(stored, applied)) {
      await _save(applied);
    }
    return ReminderSyncResult(
      scheduled: applied.length,
      exact: exact,
      syncedAt: _now(now),
    );
  }

  Future<void> forgetPlan() async {
    try {
      await _store.clear();
    } on Object {
      return;
    }
  }

  DateTime _now(DateTime fallback) => _clock?.call() ?? fallback;

  Future<Map<int, String>> _loadStored() async {
    try {
      return await _store.load();
    } on Object {
      return const {};
    }
  }

  Future<Set<int>?> _pendingIds() async {
    try {
      return (await _gateway.pendingIds()).toSet();
    } on Object {
      return null;
    }
  }

  Future<void> _save(Map<int, String> plan) async {
    try {
      await _store.save(plan);
    } on Object {
      return;
    }
  }

  static bool _sameKeys(Map<int, String> a, Map<int, String> b) =>
      a.length == b.length && a.keys.every(b.containsKey);
}
