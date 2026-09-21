import 'package:flutter_test/flutter_test.dart';
import 'package:lapse/core/domain/calendar_date.dart';
import 'package:lapse/features/reminders/domain/planned_reminder.dart';
import 'package:lapse/features/reminders/domain/reminder_id.dart';
import 'package:lapse/features/reminders/domain/reminder_kind.dart';
import 'package:lapse/features/reminders/domain/reminder_planner.dart';
import 'package:lapse/features/subscriptions/domain/entities/subscription.dart';
import 'package:lapse/features/subscriptions/domain/entities/subscription_status.dart';

import '../../../helpers/subscription_fixtures.dart';

void main() {
  const planner = ReminderPlanner();
  const nineAm = 9 * 60;
  final now = DateTime(2026, 9, 21, 12);

  List<PlannedReminder> planFor(
    Subscription subscription, {
    int reminderMinutes = nineAm,
    DateTime? at,
  }) => planner.planFor(
    subscription,
    reminderMinutes: reminderMinutes,
    now: at ?? now,
  );

  List<DateTime> times(List<PlannedReminder> reminders) => [
    for (final r in reminders) r.fireAt,
  ];

  group('offsets', () {
    test('[7, 1] fires at 09:00 seven days and one day before', () {
      final sub = subscriptionFixture(name: 'Spotify');
      final reminders = planFor(sub);
      expect(times(reminders), [
        DateTime(2026, 9, 24, 9),
        DateTime(2026, 9, 30, 9),
      ]);
      expect(
        reminders.first.id,
        reminderId('sub-1', CalendarDate(2026, 9, 24)),
      );
      expect(reminders.last.id, reminderId('sub-1', CalendarDate(2026, 9, 30)));
      expect(reminders.first.title, 'Spotify renews on Thu, 1 Oct');
      expect(reminders.last.title, 'Spotify renews tomorrow');
      expect(reminders.last.body, 'Rs 299 on Thu, 1 Oct. Tap to see details.');
      expect(reminders.every((r) => r.subscriptionId == 'sub-1'), isTrue);
      expect(reminders.every((r) => r.kind == ReminderKind.renewal), isTrue);
      expect(reminders.every((r) => !r.fireAt.isUtc), isTrue);
    });

    test('offset order does not matter', () {
      final a = planFor(subscriptionFixture(reminderOffsets: [1, 7]));
      final b = planFor(subscriptionFixture());
      expect(a, b);
    });

    test('[0] fires on the charge day', () {
      final reminders = planFor(subscriptionFixture(reminderOffsets: [0]));
      expect(times(reminders), [DateTime(2026, 10, 1, 9)]);
      expect(reminders.single.title, 'Spotify Premium renews today');
      expect(reminders.single.body, 'Rs 299 today. Tap to see details.');
    });

    test('[] produces nothing', () {
      expect(planFor(subscriptionFixture(reminderOffsets: [])), isEmpty);
    });

    test('negative offsets are ignored', () {
      final reminders = planFor(subscriptionFixture(reminderOffsets: [-1, 1]));
      expect(times(reminders), [DateTime(2026, 9, 30, 9)]);
    });

    test('offsets further back than today are skipped', () {
      final reminders = planFor(
        subscriptionFixture(reminderOffsets: [30, 14, 3]),
      );
      expect(times(reminders), [DateTime(2026, 9, 28, 9)]);
    });
  });

  group('time of day', () {
    test('custom time 20:30', () {
      final reminders = planFor(
        subscriptionFixture(),
        reminderMinutes: 20 * 60 + 30,
      );
      expect(times(reminders), [
        DateTime(2026, 9, 24, 20, 30),
        DateTime(2026, 9, 30, 20, 30),
      ]);
    });

    test('midnight', () {
      final reminders = planFor(subscriptionFixture(), reminderMinutes: 0);
      expect(times(reminders).first, DateTime(2026, 9, 24));
    });

    test('out of range minutes are clamped to the same day', () {
      final sub = subscriptionFixture(reminderOffsets: [1]);
      expect(
        times(planFor(sub, reminderMinutes: 5000)),
        [DateTime(2026, 9, 30, 23, 59)],
      );
      expect(
        times(planFor(sub, reminderMinutes: -30)),
        [DateTime(2026, 9, 30)],
      );
    });

    test('earlier today has passed and is skipped', () {
      final sub = subscriptionFixture(
        nextBillingDate: CalendarDate(2026, 9, 22),
        reminderOffsets: [1],
      );
      expect(planFor(sub), isEmpty);
    });

    test('later today is kept', () {
      final sub = subscriptionFixture(
        nextBillingDate: CalendarDate(2026, 9, 22),
        reminderOffsets: [1],
      );
      expect(
        times(planFor(sub, reminderMinutes: 18 * 60)),
        [DateTime(2026, 9, 21, 18)],
      );
    });

    test('exactly now is skipped, one minute later is kept', () {
      final sub = subscriptionFixture(
        nextBillingDate: CalendarDate(2026, 9, 22),
        reminderOffsets: [1],
      );
      expect(planFor(sub, reminderMinutes: 12 * 60), isEmpty);
      expect(planFor(sub, reminderMinutes: 12 * 60 + 1), hasLength(1));
    });

    test('charge today with [0] later today is kept', () {
      final sub = subscriptionFixture(
        nextBillingDate: CalendarDate(2026, 9, 21),
        reminderOffsets: [0, 1],
      );
      final reminders = planFor(sub, reminderMinutes: 19 * 60);
      expect(times(reminders), [DateTime(2026, 9, 21, 19)]);
      expect(reminders.single.title, 'Spotify Premium renews today');
    });

    test('a UTC now gives the same plan as local now', () {
      final sub = subscriptionFixture();
      expect(planFor(sub, at: now.toUtc()), planFor(sub));
    });
  });

  group('status and kind', () {
    test('cancelled subscriptions produce nothing', () {
      final sub = subscriptionFixture(status: SubscriptionStatus.cancelled);
      expect(planFor(sub), isEmpty);
    });

    test('cancelled subscriptions ignore snooze', () {
      final sub = subscriptionFixture(
        status: SubscriptionStatus.cancelled,
      ).copyWith(snoozedUntil: DateTime(2026, 9, 22, 12).toUtc());
      expect(planFor(sub), isEmpty);
    });

    test('trials are trialEnding with trial wording', () {
      final sub = subscriptionFixture(
        name: 'Netflix',
        priceMinor: 64900,
        isTrial: true,
        cancelUrl: 'netflix.com/cancel',
      );
      final reminders = planFor(sub);
      expect(
        reminders.every((r) => r.kind == ReminderKind.trialEnding),
        isTrue,
      );
      expect(reminders.last.title, 'Netflix trial ends tomorrow');
      expect(
        reminders.last.body,
        "You'll be charged Rs 649 on Thu, 1 Oct. Tap to cancel.",
      );
      expect(reminders.first.title, 'Netflix trial ends on Thu, 1 Oct');
    });

    test('hasCancelLink follows the cancel url', () {
      final withLink = subscriptionFixture(cancelUrl: 'spotify.com/account');
      final without = subscriptionFixture();
      final badLink = subscriptionFixture(cancelUrl: 'mailto:x@y.z');
      expect(planFor(withLink).every((r) => r.hasCancelLink), isTrue);
      expect(planFor(withLink).last.body, endsWith('Tap to cancel.'));
      expect(planFor(without).any((r) => r.hasCancelLink), isFalse);
      expect(planFor(badLink).any((r) => r.hasCancelLink), isFalse);
    });
  });

  group('one per day', () {
    test('duplicate offsets [1, 1] give one reminder', () {
      final reminders = planFor(subscriptionFixture(reminderOffsets: [1, 1]));
      expect(times(reminders), [DateTime(2026, 9, 30, 9)]);
    });

    test('duplicates among others', () {
      final reminders = planFor(
        subscriptionFixture(reminderOffsets: [7, 1, 7, 1, 0]),
      );
      expect(times(reminders), [
        DateTime(2026, 9, 24, 9),
        DateTime(2026, 9, 30, 9),
        DateTime(2026, 10, 1, 9),
      ]);
      expect(reminders.map((r) => r.id).toSet(), hasLength(3));
    });

    test('snooze on a reminder day replaces it', () {
      final sub = subscriptionFixture().copyWith(
        snoozedUntil: DateTime(2026, 9, 30, 8).toUtc(),
      );
      final reminders = planFor(sub);
      expect(times(reminders), [DateTime(2026, 9, 30, 8)]);
      expect(reminders.single.kind, ReminderKind.snoozed);
      expect(
        reminders.single.id,
        reminderId('sub-1', CalendarDate(2026, 9, 30)),
      );
    });
  });

  group('calendar edges', () {
    test('month end in a common year', () {
      final sub = subscriptionFixture(
        nextBillingDate: CalendarDate(2027, 3, 1),
        reminderOffsets: [1],
      );
      expect(times(planFor(sub)), [DateTime(2027, 2, 28, 9)]);
    });

    test('month end in a leap year', () {
      final sub = subscriptionFixture(
        nextBillingDate: CalendarDate(2028, 3, 1),
        reminderOffsets: [1],
      );
      expect(times(planFor(sub)), [DateTime(2028, 2, 29, 9)]);
    });

    test('charge on leap day', () {
      final sub = subscriptionFixture(
        nextBillingDate: CalendarDate(2028, 2, 29),
        reminderOffsets: [7, 1, 0],
      );
      final reminders = planFor(sub);
      expect(times(reminders), [
        DateTime(2028, 2, 22, 9),
        DateTime(2028, 2, 28, 9),
        DateTime(2028, 2, 29, 9),
      ]);
      expect(reminders.first.title, 'Spotify Premium renews on Tue, 29 Feb');
    });

    test('offset crosses a month and year boundary', () {
      final sub = subscriptionFixture(
        nextBillingDate: CalendarDate(2027, 1, 3),
        reminderOffsets: [7],
      );
      expect(times(planFor(sub)), [DateTime(2026, 12, 27, 9)]);
    });

    test('31st of a month', () {
      final sub = subscriptionFixture(
        nextBillingDate: CalendarDate(2026, 10, 31),
        reminderOffsets: [1],
      );
      expect(times(planFor(sub)), [DateTime(2026, 10, 30, 9)]);
    });
  });

  group('overdue', () {
    test('charge before today produces nothing', () {
      final sub = subscriptionFixture(
        nextBillingDate: CalendarDate(2026, 9, 20),
        reminderOffsets: [0, 1, 7],
      );
      expect(planFor(sub, reminderMinutes: 23 * 60), isEmpty);
    });

    test('overdue ignores snooze', () {
      final sub = subscriptionFixture(
        nextBillingDate: CalendarDate(2026, 9, 20),
      ).copyWith(snoozedUntil: DateTime(2026, 9, 21, 18).toUtc());
      expect(planFor(sub), isEmpty);
    });
  });

  group('snooze', () {
    Subscription snoozed(DateTime until, {List<int>? offsets}) =>
        subscriptionFixture(
          reminderOffsets: offsets ?? const [7, 1],
          cancelUrl: 'spotify.com',
        ).copyWith(snoozedUntil: until.toUtc());

    test('before every reminder adds one and keeps the rest', () {
      final reminders = planFor(snoozed(DateTime(2026, 9, 22, 12)));
      expect(times(reminders), [
        DateTime(2026, 9, 22, 12),
        DateTime(2026, 9, 24, 9),
        DateTime(2026, 9, 30, 9),
      ]);
      expect(reminders.map((r) => r.kind), [
        ReminderKind.snoozed,
        ReminderKind.renewal,
        ReminderKind.renewal,
      ]);
      final first = reminders.first;
      expect(first.id, reminderId('sub-1', CalendarDate(2026, 9, 22)));
      expect(first.title, 'Spotify Premium renews on Thu, 1 Oct');
      expect(first.body, 'Rs 299 on Thu, 1 Oct. Tap to cancel.');
      expect(first.hasCancelLink, isTrue);
      expect(first.fireAt.isUtc, isFalse);
    });

    test('drops reminders before the snooze time', () {
      final reminders = planFor(snoozed(DateTime(2026, 9, 25, 10)));
      expect(times(reminders), [
        DateTime(2026, 9, 25, 10),
        DateTime(2026, 9, 30, 9),
      ]);
      expect(reminders.first.kind, ReminderKind.snoozed);
      expect(reminders.first.title, 'Spotify Premium renews in 6 days');
    });

    test('exactly at a reminder time replaces it', () {
      final reminders = planFor(snoozed(DateTime(2026, 9, 24, 9)));
      expect(times(reminders), [
        DateTime(2026, 9, 24, 9),
        DateTime(2026, 9, 30, 9),
      ]);
      expect(reminders.first.kind, ReminderKind.snoozed);
    });

    test('later on a reminder day replaces that day', () {
      final reminders = planFor(snoozed(DateTime(2026, 9, 30, 15)));
      expect(times(reminders), [DateTime(2026, 9, 30, 15)]);
      expect(reminders.single.kind, ReminderKind.snoozed);
      expect(reminders.single.title, 'Spotify Premium renews tomorrow');
    });

    test('on the charge day is allowed', () {
      final reminders = planFor(snoozed(DateTime(2026, 10, 1, 15)));
      expect(times(reminders), [DateTime(2026, 10, 1, 15)]);
      expect(reminders.single.title, 'Spotify Premium renews today');
      expect(reminders.single.body, 'Rs 299 today. Tap to cancel.');
    });

    test('after the charge day is ignored', () {
      final reminders = planFor(snoozed(DateTime(2026, 10, 2, 9)));
      expect(times(reminders), [
        DateTime(2026, 9, 24, 9),
        DateTime(2026, 9, 30, 9),
      ]);
      expect(reminders.any((r) => r.kind == ReminderKind.snoozed), isFalse);
    });

    test('in the past is ignored', () {
      final reminders = planFor(snoozed(DateTime(2026, 9, 21, 11)));
      expect(times(reminders), [
        DateTime(2026, 9, 24, 9),
        DateTime(2026, 9, 30, 9),
      ]);
    });

    test('exactly now is ignored', () {
      final reminders = planFor(snoozed(now));
      expect(reminders.any((r) => r.kind == ReminderKind.snoozed), isFalse);
      expect(reminders, hasLength(2));
    });

    test('works with no offsets', () {
      final reminders = planFor(
        snoozed(DateTime(2026, 9, 22, 12), offsets: const []),
      );
      expect(times(reminders), [DateTime(2026, 9, 22, 12)]);
      expect(reminders.single.kind, ReminderKind.snoozed);
    });

    test('a local snooze time is used as is', () {
      final sub = subscriptionFixture().copyWith(
        snoozedUntil: DateTime(2026, 9, 26, 7, 45),
      );
      final reminders = planFor(sub);
      expect(times(reminders), [
        DateTime(2026, 9, 26, 7, 45),
        DateTime(2026, 9, 30, 9),
      ]);
    });

    test('snoozed trial keeps trial wording', () {
      final sub = subscriptionFixture(
        name: 'Netflix',
        priceMinor: 64900,
        isTrial: true,
      ).copyWith(snoozedUntil: DateTime(2026, 9, 30, 13).toUtc());
      final reminder = planFor(sub).single;
      expect(reminder.kind, ReminderKind.snoozed);
      expect(reminder.title, 'Netflix trial ends tomorrow');
      expect(
        reminder.body,
        "You'll be charged Rs 649 on Thu, 1 Oct. Tap to see details.",
      );
    });
  });

  group('plan', () {
    test('is empty for no subscriptions', () {
      expect(
        planner.plan(subscriptions: [], reminderMinutes: nineAm, now: now),
        isEmpty,
      );
    });

    test('merges every subscription sorted by time then id', () {
      final subs = [
        subscriptionFixture(id: 'b', reminderOffsets: [1]),
        subscriptionFixture(
          id: 'c',
          nextBillingDate: CalendarDate(2026, 9, 25),
          reminderOffsets: [1, 0],
        ),
        subscriptionFixture(id: 'a', reminderOffsets: [7, 1]),
        subscriptionFixture(id: 'd', status: SubscriptionStatus.cancelled),
        subscriptionFixture(
          id: 'e',
          nextBillingDate: CalendarDate(2026, 9, 1),
        ),
        subscriptionFixture(
          id: 'f',
          reminderOffsets: [],
        ).copyWith(snoozedUntil: DateTime(2026, 9, 24, 9).toUtc()),
      ];
      final reminders = planner.plan(
        subscriptions: subs,
        reminderMinutes: nineAm,
        now: now,
      );
      expect(
        [for (final r in reminders) (r.subscriptionId, r.fireAt)],
        [
          ('a', DateTime(2026, 9, 24, 9)),
          ('c', DateTime(2026, 9, 24, 9)),
          ('f', DateTime(2026, 9, 24, 9)),
          ('c', DateTime(2026, 9, 25, 9)),
          ('a', DateTime(2026, 9, 30, 9)),
          ('b', DateTime(2026, 9, 30, 9)),
        ],
      );
      expect(reminders[2].kind, ReminderKind.snoozed);
    });

    test('equals planFor for a single subscription', () {
      final sub = subscriptionFixture(isTrial: true);
      expect(
        planner.plan(subscriptions: [sub], reminderMinutes: nineAm, now: now),
        planFor(sub),
      );
    });

    test('is stable across calls and ids are unique', () {
      final subs = [
        for (var i = 0; i < 20; i++)
          subscriptionFixture(
            id: 'sub-$i',
            nextBillingDate: CalendarDate(2026, 10, 1).addDays(i),
            reminderOffsets: const [7, 3, 1, 0],
          ),
      ];
      final first = planner.plan(
        subscriptions: subs,
        reminderMinutes: nineAm,
        now: now,
      );
      final second = planner.plan(
        subscriptions: subs,
        reminderMinutes: nineAm,
        now: now,
      );
      expect(first, second);
      expect(first, hasLength(80));
      expect(first.map((r) => r.id).toSet(), hasLength(80));
      for (final r in first) {
        expect(r.id, inInclusiveRange(1, (1 << 31) - 1));
      }
    });
  });
}
