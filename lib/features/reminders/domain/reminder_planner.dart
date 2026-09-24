import 'package:lapse/core/domain/calendar_date.dart';
import 'package:lapse/features/reminders/domain/planned_reminder.dart';
import 'package:lapse/features/reminders/domain/reminder_content.dart';
import 'package:lapse/features/reminders/domain/reminder_id.dart';
import 'package:lapse/features/reminders/domain/reminder_kind.dart';
import 'package:lapse/features/subscriptions/domain/entities/billing_period.dart';
import 'package:lapse/features/subscriptions/domain/entities/subscription.dart';
import 'package:lapse/features/subscriptions/domain/services/billing_engine.dart';
import 'package:lapse/features/subscriptions/presentation/links/cancel_links.dart';

typedef ReminderContentBuilder =
    ({String title, String body}) Function(
      Subscription subscription, {
      required CalendarDate fireDay,
    });

typedef _Candidate = ({
  Subscription source,
  String subscriptionId,
  CalendarDate day,
  DateTime fireAt,
  ReminderKind kind,
  bool hasCancelLink,
});

class ReminderPlanner {
  const ReminderPlanner({
    BillingEngine engine = const BillingEngine(),
    ReminderContentBuilder content = ReminderContent.forSubscription,
  }) : _engine = engine,
       _content = content;

  static const maxReminders = 300;
  static const int _lastMinuteOfDay = 24 * 60 - 1;

  final BillingEngine _engine;
  final ReminderContentBuilder _content;

  List<PlannedReminder> plan({
    required List<Subscription> subscriptions,
    required int reminderMinutes,
    required DateTime now,
  }) {
    final candidates = [
      for (final subscription in subscriptions)
        ..._candidatesFor(
          subscription,
          reminderMinutes: reminderMinutes,
          now: now,
        ),
    ]..sort(_compare);
    final kept = candidates.length > maxReminders
        ? candidates.sublist(0, maxReminders)
        : candidates;
    return [for (final candidate in kept) _build(candidate)];
  }

  List<PlannedReminder> planFor(
    Subscription subscription, {
    required int reminderMinutes,
    required DateTime now,
  }) {
    final candidates = _candidatesFor(
      subscription,
      reminderMinutes: reminderMinutes,
      now: now,
    )..sort(_compare);
    return [for (final candidate in candidates) _build(candidate)];
  }

  List<_Candidate> _candidatesFor(
    Subscription subscription, {
    required int reminderMinutes,
    required DateTime now,
  }) {
    if (!subscription.isActive) return [];
    final chargeDay = subscription.nextBillingDate;
    final today = CalendarDate.fromDateTime(now.toLocal());
    if (chargeDay.isBefore(today)) return [];
    final minutes = reminderMinutes.clamp(0, _lastMinuteOfDay);
    final hasCancelLink = cancelUriFor(subscription) != null;

    final byDay = <CalendarDate, _Candidate>{};
    for (final cycle in _cycles(subscription)) {
      final cycleDays = _planCycle(
        cycle,
        subscriptionId: subscription.id,
        minutes: minutes,
        now: now,
        hasCancelLink: hasCancelLink,
      );
      for (final entry in cycleDays.entries) {
        byDay.putIfAbsent(entry.key, () => entry.value);
      }
    }

    final snoozedUntil = subscription.snoozedUntil?.toLocal();
    if (snoozedUntil != null && snoozedUntil.isAfter(now)) {
      final snoozeDay = CalendarDate.fromDateTime(snoozedUntil);
      if (!snoozeDay.isAfter(chargeDay)) {
        byDay
          ..removeWhere((_, c) => c.fireAt.isBefore(snoozedUntil))
          ..[snoozeDay] = (
            source: subscription,
            subscriptionId: subscription.id,
            day: snoozeDay,
            fireAt: snoozedUntil,
            kind: ReminderKind.snoozed,
            hasCancelLink: hasCancelLink,
          );
      }
    }

    return byDay.values.toList();
  }

  List<Subscription> _cycles(Subscription subscription) {
    final customDays = subscription.customDays;
    final unknownLength =
        subscription.period == BillingPeriod.customDays &&
        (customDays == null || customDays < 1);
    if (subscription.isTrial || unknownLength) return [subscription];
    return [
      subscription,
      subscription.copyWith(nextBillingDate: _engine.nextDateFor(subscription)),
    ];
  }

  Map<CalendarDate, _Candidate> _planCycle(
    Subscription cycle, {
    required String subscriptionId,
    required int minutes,
    required DateTime now,
    required bool hasCancelLink,
  }) {
    final kind = cycle.isTrial
        ? ReminderKind.trialEnding
        : ReminderKind.renewal;
    final byDay = <CalendarDate, _Candidate>{};
    final offsetByDay = <CalendarDate, int>{};
    for (final offset in cycle.reminderOffsets) {
      if (offset < 0) continue;
      final day = cycle.nextBillingDate.addDays(-offset);
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
      byDay[day] = (
        source: cycle,
        subscriptionId: subscriptionId,
        day: day,
        fireAt: fireAt,
        kind: kind,
        hasCancelLink: hasCancelLink,
      );
    }
    return byDay;
  }

  PlannedReminder _build(_Candidate candidate) {
    final content = _content(candidate.source, fireDay: candidate.day);
    return PlannedReminder(
      id: reminderId(candidate.subscriptionId, candidate.day),
      subscriptionId: candidate.subscriptionId,
      fireAt: candidate.fireAt,
      title: content.title,
      body: content.body,
      kind: candidate.kind,
      hasCancelLink: candidate.hasCancelLink,
    );
  }

  static int _compare(_Candidate a, _Candidate b) {
    final byTime = a.fireAt.compareTo(b.fireAt);
    if (byTime != 0) return byTime;
    return a.subscriptionId.compareTo(b.subscriptionId);
  }
}
