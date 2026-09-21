import 'package:lapse/core/domain/calendar_date.dart';
import 'package:lapse/features/reminders/domain/planned_reminder.dart';
import 'package:lapse/features/reminders/domain/reminder_content.dart';
import 'package:lapse/features/reminders/domain/reminder_id.dart';
import 'package:lapse/features/reminders/domain/reminder_kind.dart';
import 'package:lapse/features/subscriptions/domain/entities/subscription.dart';
import 'package:lapse/features/subscriptions/presentation/links/cancel_links.dart';

class ReminderPlanner {
  const ReminderPlanner();

  static const int _lastMinuteOfDay = 24 * 60 - 1;

  List<PlannedReminder> plan({
    required List<Subscription> subscriptions,
    required int reminderMinutes,
    required DateTime now,
  }) {
    final reminders = [
      for (final subscription in subscriptions)
        ...planFor(subscription, reminderMinutes: reminderMinutes, now: now),
    ]..sort(_compare);
    return reminders;
  }

  List<PlannedReminder> planFor(
    Subscription subscription, {
    required int reminderMinutes,
    required DateTime now,
  }) {
    if (!subscription.isActive) return const [];
    final chargeDay = subscription.nextBillingDate;
    final today = CalendarDate.fromDateTime(now.toLocal());
    if (chargeDay.isBefore(today)) return const [];
    final minutes = reminderMinutes.clamp(0, _lastMinuteOfDay);
    final hasCancelLink = cancelUriFor(subscription) != null;
    final kind = subscription.isTrial
        ? ReminderKind.trialEnding
        : ReminderKind.renewal;

    final byDay = <CalendarDate, PlannedReminder>{};
    final offsetByDay = <CalendarDate, int>{};
    for (final offset in subscription.reminderOffsets) {
      if (offset < 0) continue;
      final day = chargeDay.addDays(-offset);
      final fireAt = DateTime(
        day.year,
        day.month,
        day.day,
        minutes ~/ 60,
        minutes % 60,
      );
      if (!fireAt.isAfter(now)) continue;
      final existing = offsetByDay[day];
      if (existing != null && existing <= offset) continue;
      offsetByDay[day] = offset;
      byDay[day] = _build(
        subscription,
        day,
        fireAt,
        kind,
        hasCancelLink: hasCancelLink,
      );
    }

    final snoozedUntil = subscription.snoozedUntil?.toLocal();
    if (snoozedUntil != null && snoozedUntil.isAfter(now)) {
      final snoozeDay = CalendarDate.fromDateTime(snoozedUntil);
      if (!snoozeDay.isAfter(chargeDay)) {
        byDay
          ..removeWhere((_, r) => r.fireAt.isBefore(snoozedUntil))
          ..[snoozeDay] = _build(
            subscription,
            snoozeDay,
            snoozedUntil,
            ReminderKind.snoozed,
            hasCancelLink: hasCancelLink,
          );
      }
    }

    return byDay.values.toList()..sort(_compare);
  }

  PlannedReminder _build(
    Subscription subscription,
    CalendarDate day,
    DateTime fireAt,
    ReminderKind kind, {
    required bool hasCancelLink,
  }) {
    final content = ReminderContent.forSubscription(
      subscription,
      fireDay: day,
    );
    return PlannedReminder(
      id: reminderId(subscription.id, day),
      subscriptionId: subscription.id,
      fireAt: fireAt,
      title: content.title,
      body: content.body,
      kind: kind,
      hasCancelLink: hasCancelLink,
    );
  }

  static int _compare(PlannedReminder a, PlannedReminder b) {
    final byTime = a.fireAt.compareTo(b.fireAt);
    if (byTime != 0) return byTime;
    return a.subscriptionId.compareTo(b.subscriptionId);
  }
}
