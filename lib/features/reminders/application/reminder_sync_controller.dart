import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lapse/core/providers/clock_providers.dart';
import 'package:lapse/features/reminders/application/reminder_providers.dart';
import 'package:lapse/features/reminders/application/reminder_sync.dart';
import 'package:lapse/features/reminders/application/reminder_sync_result.dart';
import 'package:lapse/features/reminders/data/reminder_permission.dart';
import 'package:lapse/features/reminders/data/reminder_plan_store_provider.dart';
import 'package:lapse/features/settings/presentation/providers/settings_providers.dart';
import 'package:lapse/features/subscriptions/presentation/providers/subscription_list_providers.dart';

class ReminderSyncController extends Notifier<ReminderSyncResult?> {
  static const debounce = Duration(milliseconds: 300);

  Timer? _timer;
  Future<void> _tail = Future<void>.value();

  @override
  ReminderSyncResult? build() {
    ref
      ..onDispose(_cancelTimer)
      ..listen(subscriptionsProvider, (previous, _) {
        if (previous?.hasValue ?? false) _scheduleSync();
      })
      ..listen(
        settingsProvider.select((settings) => settings.reminderMinutes),
        (_, _) => _scheduleSync(),
      )
      ..listen(notificationPermissionProvider, (previous, next) {
        if ((previous?.hasValue ?? false) &&
            previous?.value != ReminderPermission.granted &&
            next.value == ReminderPermission.granted) {
          unawaited(syncNow());
        }
      });
    _scheduleSync();
    return null;
  }

  Future<ReminderSyncResult?> syncNow() {
    _cancelTimer();
    final result = _tail.then((_) => _perform());
    _tail = result.then<void>((_) {}, onError: (Object _) {});
    return result;
  }

  void _scheduleSync() {
    _cancelTimer();
    _timer = Timer(debounce, () => unawaited(syncNow()));
  }

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }

  ReminderSync _createSync() => ReminderSync(
    gateway: ref.read(notificationGatewayProvider),
    planner: ref.read(reminderPlannerProvider),
    planStore: ref.read(reminderPlanStoreProvider),
    clock: ref.read(clockProvider),
  );

  Future<ReminderSyncResult?> _perform() async {
    try {
      if (!ref.mounted) return null;
      final permission = await ref.read(notificationPermissionProvider.future);
      if (!ref.mounted) return null;
      if (permission != ReminderPermission.granted) {
        await _createSync().forgetPlan();
        return null;
      }
      final subscriptions = await ref.read(subscriptionsProvider.future);
      if (!ref.mounted) return null;
      final clock = ref.read(clockProvider);
      final sync = _createSync();
      final result = await sync.sync(
        subscriptions: subscriptions,
        reminderMinutes: ref.read(settingsProvider).reminderMinutes,
        now: clock(),
      );
      if (!ref.mounted) return result;
      state = result;
      ref.invalidate(pendingReminderIdsProvider);
      return result;
    } on Object {
      return null;
    }
  }
}
