import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lapse/core/domain/calendar_date.dart';
import 'package:lapse/core/providers/clock_providers.dart';
import 'package:lapse/features/reminders/application/reminder_providers.dart';
import 'package:lapse/features/reminders/domain/planned_reminder.dart';
import 'package:lapse/features/reminders/domain/reminder_content.dart';
import 'package:lapse/features/reminders/domain/reminder_kind.dart';
import 'package:lapse/features/subscriptions/presentation/links/cancel_links.dart';
import 'package:lapse/features/subscriptions/presentation/providers/subscription_list_providers.dart';

const int testNotificationId = 999999;
const Duration testNotificationDelay = Duration(seconds: 10);

Future<PlannedReminder> scheduleTestNotification(WidgetRef ref) async {
  final now = ref.read(clockProvider)();
  final base = _testSource(ref, now);
  final reminder = PlannedReminder(
    id: testNotificationId,
    subscriptionId: base.subscriptionId,
    fireAt: now.add(testNotificationDelay),
    title: base.title,
    body: base.body,
    kind: base.kind,
    hasCancelLink: base.hasCancelLink,
  );
  final gateway = ref.read(notificationGatewayProvider);
  bool exact;
  try {
    exact = await gateway.canScheduleExact();
  } on Object {
    exact = false;
  }
  await gateway.schedule(reminder, exact: exact);
  ref.invalidate(pendingReminderIdsProvider);
  return reminder;
}

PlannedReminder _testSource(WidgetRef ref, DateTime now) {
  final planned = [...?ref.read(plannedRemindersProvider).value]
    ..sort((a, b) => a.fireAt.compareTo(b.fireAt));
  if (planned.isNotEmpty) return planned.first;
  final subscriptions = ref.read(subscriptionsProvider).value ?? const [];
  final subscription = subscriptions.where((s) => s.isActive).firstOrNull;
  if (subscription == null) {
    return PlannedReminder(
      id: testNotificationId,
      subscriptionId: '',
      fireAt: now,
      title: 'Lapse test reminder',
      body: 'Reminders are working. This is how they will look.',
      kind: ReminderKind.renewal,
      hasCancelLink: false,
    );
  }
  final content = ReminderContent.forSubscription(
    subscription,
    fireDay: CalendarDate.fromDateTime(now),
  );
  return PlannedReminder(
    id: testNotificationId,
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
