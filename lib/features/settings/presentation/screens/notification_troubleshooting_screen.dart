import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lapse/core/platform/system_bridge_provider.dart';
import 'package:lapse/core/theme/theme.dart';
import 'package:lapse/core/widgets/widgets.dart';
import 'package:lapse/features/reminders/application/reminder_providers.dart';
import 'package:lapse/features/reminders/data/reminder_permission.dart';
import 'package:lapse/features/settings/presentation/actions/test_notification.dart';
import 'package:lapse/features/settings/presentation/formatting/settings_labels.dart';
import 'package:lapse/features/settings/presentation/models/notification_health.dart';
import 'package:lapse/features/settings/presentation/providers/notification_health_provider.dart';
import 'package:lapse/features/settings/presentation/widgets/notification_health_refresher.dart';
import 'package:lapse/features/settings/presentation/widgets/settings_top_bar.dart';
import 'package:lapse/features/settings/presentation/widgets/status_pill.dart';
import 'package:lapse/features/settings/presentation/widgets/troubleshooting_row.dart';

class NotificationTroubleshootingScreen extends ConsumerWidget {
  const NotificationTroubleshootingScreen({super.key});

  static const intro =
      "If a reminder didn't arrive, check these. Each one can stop or "
      'delay reminders.';
  static const notificationsOffDetail =
      "Lapse can't show reminders until notifications are allowed.";
  static const exactOffDetail =
      'Without exact timing, Android may deliver reminders a few minutes '
      'late.';
  static const exactOnDetail = 'Reminders arrive at the time you picked.';
  static const batteryDetail =
      'Battery optimisation can delay or drop reminders. Choose '
      "Unrestricted or Don't optimise for Lapse.";
  static const notificationsOffMessage = 'Allow notifications first';
  static String testScheduledMessage(Duration delay) =>
      'Test notification arrives in ${delay.inSeconds} seconds';

  void _toast(ScaffoldMessengerState? messenger, String message) =>
      messenger?.showSnackBar(SnackBar(content: Text(message)));

  Future<void> _allowNotifications(WidgetRef ref) async {
    final result = await ref
        .read(notificationPermissionProvider.notifier)
        .request();
    if (result != ReminderPermission.granted) {
      await ref.read(systemBridgeProvider).openNotificationSettings();
    }
  }

  Future<void> _openNotificationSettings(WidgetRef ref) =>
      ref.read(systemBridgeProvider).openNotificationSettings();

  Future<void> _allowExact(WidgetRef ref) async {
    await ref.read(notificationGatewayProvider).requestExactAlarms();
    ref.invalidate(exactAlarmsAllowedProvider);
  }

  Future<void> _openBattery(WidgetRef ref) async {
    await ref.read(systemBridgeProvider).openBatterySettings();
    ref.invalidate(batteryOptimizationIgnoredProvider);
  }

  Future<void> _sendTest(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final health = ref.read(notificationHealthProvider).value;
    if (health != null && !health.notificationsAllowed) {
      _toast(messenger, notificationsOffMessage);
      return;
    }
    try {
      await scheduleTestNotification(ref);
      _toast(messenger, testScheduledMessage(testNotificationDelay));
    } on Object {
      _toast(messenger, "Couldn't schedule the test notification");
    }
  }

  Future<void> _sync(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final result = await ref.read(reminderSyncProvider.notifier).syncNow();
    ref.invalidate(pendingReminderIdsProvider);
    _toast(
      messenger,
      result == null
          ? 'Sync skipped: notifications are off'
          : 'Scheduled ${result.scheduled} '
                '${result.scheduled == 1 ? 'reminder' : 'reminders'}',
    );
  }

  List<Widget> _rows(WidgetRef ref, NotificationHealth health) {
    void run(Future<void> Function() action) => unawaited(action());
    final allowed = health.notificationsAllowed;
    final canAsk = health.permission == ReminderPermission.denied;
    final next = health.next;
    final count = health.pendingCount;
    return [
      TroubleshootingRow(
        icon: Icons.notifications_rounded,
        title: 'Notifications',
        status: allowed ? 'Allowed' : 'Off',
        tone: allowed ? StatusTone.ok : StatusTone.attention,
        detail: allowed ? null : notificationsOffDetail,
        actionLabel: allowed
            ? null
            : canAsk
            ? 'Allow'
            : 'Open settings',
        onAction: allowed
            ? null
            : () => run(
                () => canAsk
                    ? _allowNotifications(ref)
                    : _openNotificationSettings(ref),
              ),
      ),
      TroubleshootingRow(
        icon: Icons.alarm_rounded,
        title: 'Exact timing',
        status: health.exactAlarms ? 'On' : 'Off',
        tone: health.exactAlarms ? StatusTone.ok : StatusTone.attention,
        detail: health.exactAlarms ? exactOnDetail : exactOffDetail,
        actionLabel: health.exactAlarms ? null : 'Allow',
        onAction: health.exactAlarms ? null : () => run(() => _allowExact(ref)),
      ),
      TroubleshootingRow(
        icon: Icons.battery_charging_full_rounded,
        title: 'Battery optimisation',
        status: health.batteryOptimised ? 'Optimised' : 'Not optimised',
        tone: health.batteryOptimised ? StatusTone.attention : StatusTone.ok,
        detail: health.batteryOptimised ? batteryDetail : null,
        actionLabel: health.batteryOptimised ? 'Open battery settings' : null,
        onAction: health.batteryOptimised
            ? () => run(() => _openBattery(ref))
            : null,
      ),
      TroubleshootingRow(
        icon: Icons.event_note_rounded,
        title: 'Scheduled reminders',
        status: '$count scheduled',
        tone: StatusTone.neutral,
        detail: next == null
            ? 'Nothing scheduled yet.'
            : 'Next: ${next.service} · ${reminderMomentLabel(next.fireAt)}',
      ),
    ];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lapse = context.lapse;
    final health = ref.watch(notificationHealthProvider);
    final value = health.value;

    return NotificationHealthRefresher(
      child: Scaffold(
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.only(bottom: Space.xxxl),
            children: [
              const SettingsTopBar(title: 'Troubleshooting'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Space.screen),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(intro, style: lapse.text.bodyMuted),
                    const SizedBox(height: Space.lg),
                    if (value != null)
                      LapseRowGroup(children: _rows(ref, value))
                    else if (health.hasError)
                      Text(
                        "Couldn't read the notification status.",
                        style: lapse.text.bodyMuted,
                      )
                    else
                      const Padding(
                        padding: EdgeInsets.all(Space.xl),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    const SizedBox(height: Space.xxl),
                    LapseButton(
                      label: 'Send test notification',
                      icon: Icons.send_rounded,
                      expand: true,
                      onPressed: () => unawaited(_sendTest(context, ref)),
                    ),
                    const SizedBox(height: Space.sm),
                    Text(
                      'Arrives in ${testNotificationDelay.inSeconds} seconds, '
                      'even if you leave the app.',
                      textAlign: TextAlign.center,
                      style: lapse.text.meta,
                    ),
                    const SizedBox(height: Space.lg),
                    LapseButton(
                      label: 'Sync now',
                      icon: Icons.sync_rounded,
                      variant: LapseButtonVariant.secondary,
                      expand: true,
                      onPressed: () => unawaited(_sync(context, ref)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
