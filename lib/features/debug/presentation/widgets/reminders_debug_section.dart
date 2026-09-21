import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lapse/core/domain/calendar_date.dart';
import 'package:lapse/core/providers/clock_providers.dart';
import 'package:lapse/core/theme/theme.dart';
import 'package:lapse/core/widgets/widgets.dart';
import 'package:lapse/features/reminders/application/reminder_providers.dart';
import 'package:lapse/features/reminders/data/reminder_permission.dart';
import 'package:lapse/features/reminders/domain/planned_reminder.dart';
import 'package:lapse/features/reminders/domain/reminder_content.dart';
import 'package:lapse/features/reminders/domain/reminder_kind.dart';
import 'package:lapse/features/subscriptions/domain/entities/subscription.dart';
import 'package:lapse/features/subscriptions/presentation/links/cancel_links.dart';
import 'package:lapse/features/subscriptions/presentation/providers/subscription_list_providers.dart';

class RemindersDebugSection extends ConsumerWidget {
  const RemindersDebugSection({super.key});

  static const testReminderId = 999999;
  static const testDelay = Duration(seconds: 10);
  static const listLimit = 20;

  static final _fireTime = DateFormat('EEE d MMM HH:mm', 'en_US');
  static final _syncTime = DateFormat('HH:mm:ss', 'en_US');

  void _toast(BuildContext context, String message) {
    ScaffoldMessenger.maybeOf(
      context,
    )?.showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _sync(BuildContext context, WidgetRef ref) async {
    final result = await ref.read(reminderSyncProvider.notifier).syncNow();
    ref.invalidate(pendingReminderIdsProvider);
    if (!context.mounted) return;
    _toast(
      context,
      result == null
          ? 'Sync skipped: notifications are not allowed'
          : 'Scheduled ${result.scheduled} reminder(s)',
    );
  }

  Future<void> _fireTest(BuildContext context, WidgetRef ref) async {
    final now = ref.read(clockProvider)();
    final base = _testSource(ref, now);
    if (base == null) {
      _toast(context, 'Add an active subscription first');
      return;
    }
    final reminder = PlannedReminder(
      id: testReminderId,
      subscriptionId: base.subscriptionId,
      fireAt: now.add(testDelay),
      title: base.title,
      body: base.body,
      kind: base.kind,
      hasCancelLink: base.hasCancelLink,
    );
    await ref
        .read(notificationGatewayProvider)
        .schedule(reminder, exact: false);
    ref.invalidate(pendingReminderIdsProvider);
    if (!context.mounted) return;
    _toast(context, 'Test reminder fires in ${testDelay.inSeconds} s');
  }

  PlannedReminder? _testSource(WidgetRef ref, DateTime now) {
    final planned = ref.read(plannedRemindersProvider).value ?? const [];
    if (planned.isNotEmpty) return planned.first;
    final subscriptions = ref.read(subscriptionsProvider).value ?? const [];
    final active = subscriptions.where((s) => s.isActive);
    if (active.isEmpty) return null;
    final subscription = active.first;
    final content = ReminderContent.forSubscription(
      subscription,
      fireDay: CalendarDate.fromDateTime(now),
    );
    return PlannedReminder(
      id: testReminderId,
      subscriptionId: subscription.id,
      fireAt: now,
      title: content.title,
      body: content.body,
      kind: subscription.isTrial
          ? ReminderKind.trialEnding
          : ReminderKind.renewal,
      hasCancelLink: cancelUriFor(subscription) != null,
    );
  }

  Future<void> _requestPermission(BuildContext context, WidgetRef ref) async {
    final result = await ref
        .read(notificationPermissionProvider.notifier)
        .request();
    if (!context.mounted) return;
    _toast(context, 'Permission: ${result.name}');
  }

  Future<void> _requestExact(WidgetRef ref) async {
    await ref.read(notificationGatewayProvider).requestExactAlarms();
    ref.invalidate(exactAlarmsAllowedProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lapse = context.lapse;
    final permission = ref.watch(notificationPermissionProvider);
    final exact = ref.watch(exactAlarmsAllowedProvider);
    final pending = ref.watch(pendingReminderIdsProvider);
    final lastSync = ref.watch(reminderSyncProvider);
    final planned = ref.watch(plannedRemindersProvider);
    final names = {
      for (final Subscription s
          in ref.watch(subscriptionsProvider).value ?? const [])
        s.id: s.name,
    };

    String describe<T extends Object>(
      AsyncValue<T> async,
      String Function(T value) label,
    ) {
      if (async.hasError) return 'error: ${async.error}';
      final value = async.value;
      return value == null ? '…' : label(value);
    }

    final exactOff =
        permission.value == ReminderPermission.granted && exact.value == false;
    final upcoming = [...?planned.value]
      ..sort((a, b) => a.fireAt.compareTo(b.fireAt));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('REMINDERS', style: lapse.text.caption),
        const SizedBox(height: Space.sm),
        _StatusRow(
          label: 'Permission',
          value: describe(permission, (p) => p.name),
        ),
        _StatusRow(
          label: 'Exact alarms',
          value: describe(exact, (allowed) => allowed ? 'yes' : 'no'),
        ),
        _StatusRow(
          label: 'Pending',
          value: describe(pending, (ids) => '${ids.length}'),
        ),
        _StatusRow(
          label: 'Last sync',
          value: lastSync == null
              ? 'never'
              : '${_syncTime.format(lastSync.syncedAt)} · '
                    '${lastSync.scheduled} scheduled'
                    '${lastSync.exact ? ' · exact' : ''}',
        ),
        if (exactOff) ...[
          const SizedBox(height: Space.xs),
          Text(
            'Exact alarms are off, so Android may deliver reminders a few '
            'minutes late.',
            style: lapse.text.meta,
          ),
        ],
        const SizedBox(height: Space.md),
        Wrap(
          spacing: Space.sm,
          runSpacing: Space.sm,
          children: [
            LapseButton(
              label: 'Sync now',
              onPressed: () => unawaited(_sync(context, ref)),
            ),
            LapseButton(
              label: 'Fire test in 10 s',
              variant: LapseButtonVariant.secondary,
              onPressed: () => unawaited(_fireTest(context, ref)),
            ),
            LapseButton(
              label: 'Request permission',
              variant: LapseButtonVariant.secondary,
              onPressed: () => unawaited(_requestPermission(context, ref)),
            ),
            LapseButton(
              label: 'Request exact alarms',
              variant: LapseButtonVariant.secondary,
              onPressed: () => unawaited(_requestExact(ref)),
            ),
          ],
        ),
        const SizedBox(height: Space.lg),
        SectionHeader(title: 'Planned (${upcoming.length})'),
        const SizedBox(height: Space.xs),
        if (planned.hasError)
          Text(
            '${planned.error}',
            style: lapse.text.meta.copyWith(color: lapse.colors.urgentText),
          )
        else if (upcoming.isEmpty)
          Text('No reminders planned', style: lapse.text.bodyMuted)
        else
          for (final reminder in upcoming.take(listLimit))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(
                '${names[reminder.subscriptionId] ?? reminder.subscriptionId}'
                ' · ${_fireTime.format(reminder.fireAt)} · ${reminder.title}',
                style: lapse.text.meta,
              ),
            ),
      ],
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final text = context.lapse.text;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label, style: text.bodyMuted)),
          const SizedBox(width: Space.md),
          Flexible(
            child: Text(value, style: text.body, textAlign: TextAlign.end),
          ),
        ],
      ),
    );
  }
}
