import 'package:flutter_test/flutter_test.dart';
import 'package:lapse/core/domain/calendar_date.dart';
import 'package:lapse/features/reminders/domain/planned_reminder.dart';
import 'package:lapse/features/reminders/domain/reminder_content.dart';
import 'package:lapse/features/reminders/domain/reminder_id.dart';
import 'package:lapse/features/reminders/domain/reminder_kind.dart';
import 'package:lapse/features/reminders/domain/reminder_planner.dart';
import 'package:lapse/features/subscriptions/domain/entities/billing_period.dart';
import 'package:lapse/features/subscriptions/domain/entities/subscription.dart';
import 'package:lapse/features/subscriptions/domain/entities/subscription_status.dart';

import '../../../helpers/subscription_fixtures.dart';

void main() {
  const planner = ReminderPlanner();
  const nineAm = 9 * 60;
  final now = DateTime(2026, 9, 21, 12);

  List<PlannedReminder> planAll(
    Subscription subscription, {
    int reminderMinutes = nineAm,
    DateTime? at,
  }) => planner.planFor(
    subscription,
    reminderMinutes: reminderMinutes,
    now: at ?? now,
  );

  List<PlannedReminder> firstCycle(
    Subscription subscription, {
    int reminderMinutes = nineAm,
    DateTime? at,
  }) => [
    for (final reminder in planAll(
      subscription,
      reminderMinutes: reminderMinutes,
      at: at,
    ))
      if (!CalendarDate.fromDateTime(
        reminder.fireAt,
      ).isAfter(subscription.nextBillingDate))
        reminder,
  ];

  List<DateTime> times(List<PlannedReminder> reminders) => [
    for (final r in reminders) r.fireAt,
  ];

  group('offsets', () {
    test('[7, 1] fires at 09:00 seven days and one day before', () {
      final sub = subscriptionFixture(name: 'Spotify');
      final reminders = firstCycle(sub);
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
      final a = firstCycle(subscriptionFixture(reminderOffsets: [1, 7]));
      final b = firstCycle(subscriptionFixture());
      expect(a, b);
    });

    test('[0] fires on the charge day', () {
      final reminders = firstCycle(subscriptionFixture(reminderOffsets: [0]));
      expect(times(reminders), [DateTime(2026, 10, 1, 9)]);
      expect(reminders.single.title, 'Spotify Premium renews today');
      expect(reminders.single.body, 'Rs 299 today. Tap to see details.');
    });

    test('[] produces nothing', () {
      expect(firstCycle(subscriptionFixture(reminderOffsets: [])), isEmpty);
    });

    test('negative offsets are ignored', () {
      final reminders = firstCycle(
        subscriptionFixture(reminderOffsets: [-1, 1]),
      );
      expect(times(reminders), [DateTime(2026, 9, 30, 9)]);
    });

    test('offsets further back than today are skipped', () {
      final reminders = firstCycle(
        subscriptionFixture(reminderOffsets: [30, 14, 3]),
      );
      expect(times(reminders), [DateTime(2026, 9, 28, 9)]);
    });
  });

  group('time of day', () {
    test('custom time 20:30', () {
      final reminders = firstCycle(
        subscriptionFixture(),
        reminderMinutes: 20 * 60 + 30,
      );
      expect(times(reminders), [
        DateTime(2026, 9, 24, 20, 30),
        DateTime(2026, 9, 30, 20, 30),
      ]);
    });

    test('midnight', () {
      final reminders = firstCycle(subscriptionFixture(), reminderMinutes: 0);
      expect(times(reminders).first, DateTime(2026, 9, 24));
    });

    test('out of range minutes are clamped to the same day', () {
      final sub = subscriptionFixture(reminderOffsets: [1]);
      expect(
        times(firstCycle(sub, reminderMinutes: 5000)),
        [DateTime(2026, 9, 30, 23, 59)],
      );
      expect(
        times(firstCycle(sub, reminderMinutes: -30)),
        [DateTime(2026, 9, 30)],
      );
    });

    test('earlier today has passed and is skipped', () {
      final sub = subscriptionFixture(
        nextBillingDate: CalendarDate(2026, 9, 22),
        reminderOffsets: [1],
      );
      expect(firstCycle(sub), isEmpty);
    });

    test('later today is kept', () {
      final sub = subscriptionFixture(
        nextBillingDate: CalendarDate(2026, 9, 22),
        reminderOffsets: [1],
      );
      expect(
        times(firstCycle(sub, reminderMinutes: 18 * 60)),
        [DateTime(2026, 9, 21, 18)],
      );
    });

    test('exactly now is skipped, one minute later is kept', () {
      final sub = subscriptionFixture(
        nextBillingDate: CalendarDate(2026, 9, 22),
        reminderOffsets: [1],
      );
      expect(firstCycle(sub, reminderMinutes: 12 * 60), isEmpty);
      expect(firstCycle(sub, reminderMinutes: 12 * 60 + 1), hasLength(1));
    });

    test('charge today with [0] later today is kept', () {
      final sub = subscriptionFixture(
        nextBillingDate: CalendarDate(2026, 9, 21),
        reminderOffsets: [0, 1],
      );
      final reminders = firstCycle(sub, reminderMinutes: 19 * 60);
      expect(times(reminders), [DateTime(2026, 9, 21, 19)]);
      expect(reminders.single.title, 'Spotify Premium renews today');
    });

    test('a UTC now gives the same plan as local now', () {
      final sub = subscriptionFixture();
      expect(planAll(sub, at: now.toUtc()), planAll(sub));
    });
  });

  group('status and kind', () {
    test('cancelled subscriptions produce nothing', () {
      final sub = subscriptionFixture(status: SubscriptionStatus.cancelled);
      expect(firstCycle(sub), isEmpty);
    });

    test('cancelled subscriptions ignore snooze', () {
      final sub = subscriptionFixture(
        status: SubscriptionStatus.cancelled,
      ).copyWith(snoozedUntil: DateTime(2026, 9, 22, 12).toUtc());
      expect(firstCycle(sub), isEmpty);
    });

    test('trials are trialEnding with trial wording', () {
      final sub = subscriptionFixture(
        name: 'Netflix',
        priceMinor: 64900,
        isTrial: true,
        cancelUrl: 'netflix.com/cancel',
      );
      final reminders = firstCycle(sub);
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
      expect(firstCycle(withLink).every((r) => r.hasCancelLink), isTrue);
      expect(firstCycle(withLink).last.body, endsWith('Tap to cancel.'));
      expect(firstCycle(without).any((r) => r.hasCancelLink), isFalse);
      expect(firstCycle(badLink).any((r) => r.hasCancelLink), isFalse);
    });
  });

  group('one per day', () {
    test('duplicate offsets [1, 1] give one reminder', () {
      final reminders = firstCycle(
        subscriptionFixture(reminderOffsets: [1, 1]),
      );
      expect(times(reminders), [DateTime(2026, 9, 30, 9)]);
    });

    test('duplicates among others', () {
      final reminders = firstCycle(
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
      final reminders = firstCycle(sub);
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
      expect(times(firstCycle(sub)), [DateTime(2027, 2, 28, 9)]);
    });

    test('month end in a leap year', () {
      final sub = subscriptionFixture(
        nextBillingDate: CalendarDate(2028, 3, 1),
        reminderOffsets: [1],
      );
      expect(times(firstCycle(sub)), [DateTime(2028, 2, 29, 9)]);
    });

    test('charge on leap day', () {
      final sub = subscriptionFixture(
        nextBillingDate: CalendarDate(2028, 2, 29),
        reminderOffsets: [7, 1, 0],
      );
      final reminders = firstCycle(sub);
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
      expect(times(firstCycle(sub)), [DateTime(2026, 12, 27, 9)]);
    });

    test('31st of a month', () {
      final sub = subscriptionFixture(
        nextBillingDate: CalendarDate(2026, 10, 31),
        reminderOffsets: [1],
      );
      expect(times(firstCycle(sub)), [DateTime(2026, 10, 30, 9)]);
    });
  });

  group('overdue', () {
    test('charge before today produces nothing', () {
      final sub = subscriptionFixture(
        nextBillingDate: CalendarDate(2026, 9, 20),
        reminderOffsets: [0, 1, 7],
      );
      expect(firstCycle(sub, reminderMinutes: 23 * 60), isEmpty);
    });

    test('overdue ignores snooze', () {
      final sub = subscriptionFixture(
        nextBillingDate: CalendarDate(2026, 9, 20),
      ).copyWith(snoozedUntil: DateTime(2026, 9, 21, 18).toUtc());
      expect(firstCycle(sub), isEmpty);
    });
  });

  group('snooze', () {
    Subscription snoozed(DateTime until, {List<int>? offsets}) =>
        subscriptionFixture(
          reminderOffsets: offsets ?? const [7, 1],
          cancelUrl: 'spotify.com',
        ).copyWith(snoozedUntil: until.toUtc());

    test('before every reminder adds one and keeps the rest', () {
      final reminders = firstCycle(snoozed(DateTime(2026, 9, 22, 12)));
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
      final reminders = firstCycle(snoozed(DateTime(2026, 9, 25, 10)));
      expect(times(reminders), [
        DateTime(2026, 9, 25, 10),
        DateTime(2026, 9, 30, 9),
      ]);
      expect(reminders.first.kind, ReminderKind.snoozed);
      expect(reminders.first.title, 'Spotify Premium renews in 6 days');
    });

    test('exactly at a reminder time replaces it', () {
      final reminders = firstCycle(snoozed(DateTime(2026, 9, 24, 9)));
      expect(times(reminders), [
        DateTime(2026, 9, 24, 9),
        DateTime(2026, 9, 30, 9),
      ]);
      expect(reminders.first.kind, ReminderKind.snoozed);
    });

    test('later on a reminder day replaces that day', () {
      final reminders = firstCycle(snoozed(DateTime(2026, 9, 30, 15)));
      expect(times(reminders), [DateTime(2026, 9, 30, 15)]);
      expect(reminders.single.kind, ReminderKind.snoozed);
      expect(reminders.single.title, 'Spotify Premium renews tomorrow');
    });

    test('on the charge day is allowed', () {
      final reminders = firstCycle(snoozed(DateTime(2026, 10, 1, 15)));
      expect(times(reminders), [DateTime(2026, 10, 1, 15)]);
      expect(reminders.single.title, 'Spotify Premium renews today');
      expect(reminders.single.body, 'Rs 299 today. Tap to cancel.');
    });

    test('after the charge day is ignored', () {
      final reminders = firstCycle(snoozed(DateTime(2026, 10, 2, 9)));
      expect(times(reminders), [
        DateTime(2026, 9, 24, 9),
        DateTime(2026, 9, 30, 9),
      ]);
      expect(reminders.any((r) => r.kind == ReminderKind.snoozed), isFalse);
    });

    test('in the past is ignored', () {
      final reminders = firstCycle(snoozed(DateTime(2026, 9, 21, 11)));
      expect(times(reminders), [
        DateTime(2026, 9, 24, 9),
        DateTime(2026, 9, 30, 9),
      ]);
    });

    test('exactly now is ignored', () {
      final reminders = firstCycle(snoozed(now));
      expect(reminders.any((r) => r.kind == ReminderKind.snoozed), isFalse);
      expect(reminders, hasLength(2));
    });

    test('works with no offsets', () {
      final reminders = firstCycle(
        snoozed(DateTime(2026, 9, 22, 12), offsets: const []),
      );
      expect(times(reminders), [DateTime(2026, 9, 22, 12)]);
      expect(reminders.single.kind, ReminderKind.snoozed);
    });

    test('a local snooze time is used as is', () {
      final sub = subscriptionFixture().copyWith(
        snoozedUntil: DateTime(2026, 9, 26, 7, 45),
      );
      final reminders = firstCycle(sub);
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
      final reminder = firstCycle(sub).single;
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
          ('c', DateTime(2026, 10, 24, 9)),
          ('a', DateTime(2026, 10, 25, 9)),
          ('c', DateTime(2026, 10, 25, 9)),
          ('a', DateTime(2026, 10, 31, 9)),
          ('b', DateTime(2026, 10, 31, 9)),
        ],
      );
      expect(reminders[2].kind, ReminderKind.snoozed);
    });

    test('equals planFor for a single subscription', () {
      final sub = subscriptionFixture(isTrial: true);
      expect(
        planner.plan(subscriptions: [sub], reminderMinutes: nineAm, now: now),
        planAll(sub),
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
      expect(first, hasLength(160));
      expect(first.map((r) => r.id).toSet(), hasLength(160));
      for (final r in first) {
        expect(r.id, inInclusiveRange(1, (1 << 31) - 1));
      }
    });
  });
  group('second cycle', () {
    test('plans the charge after the next one', () {
      final sub = subscriptionFixture(name: 'Spotify');
      final reminders = planAll(sub);
      expect(times(reminders), [
        DateTime(2026, 9, 24, 9),
        DateTime(2026, 9, 30, 9),
        DateTime(2026, 10, 25, 9),
        DateTime(2026, 10, 31, 9),
      ]);
      expect(reminders[2].id, reminderId('sub-1', CalendarDate(2026, 10, 25)));
      expect(reminders[2].title, 'Spotify renews on Sun, 1 Nov');
      expect(reminders[3].title, 'Spotify renews tomorrow');
      expect(reminders[3].body, 'Rs 299 on Sun, 1 Nov. Tap to see details.');
      expect(reminders.every((r) => r.kind == ReminderKind.renewal), isTrue);
    });

    test('covers the next cycle when the first has no reminders left', () {
      final sub = subscriptionFixture(
        nextBillingDate: CalendarDate(2026, 9, 21),
        reminderOffsets: [7, 1],
      );
      expect(times(planAll(sub)), [
        DateTime(2026, 10, 14, 9),
        DateTime(2026, 10, 20, 9),
      ]);
    });

    test('follows the billing period and anchor day', () {
      final weekly = subscriptionFixture(
        period: BillingPeriod.weekly,
        nextBillingDate: CalendarDate(2026, 9, 25),
        reminderOffsets: [1],
      );
      expect(times(planAll(weekly)), [
        DateTime(2026, 9, 24, 9),
        DateTime(2026, 10, 1, 9),
      ]);
      final anchored = subscriptionFixture(
        nextBillingDate: CalendarDate(2027, 2, 28),
        anchorDay: 31,
        reminderOffsets: [0],
      );
      expect(times(planAll(anchored, at: DateTime(2027, 2, 20))), [
        DateTime(2027, 2, 28, 9),
        DateTime(2027, 3, 31, 9),
      ]);
    });

    test('keeps one reminder per day across cycles', () {
      final sub = subscriptionFixture(
        period: BillingPeriod.weekly,
        nextBillingDate: CalendarDate(2026, 9, 28),
        reminderOffsets: [7, 0],
      );
      final reminders = planAll(sub);
      expect(times(reminders), [
        DateTime(2026, 9, 28, 9),
        DateTime(2026, 10, 5, 9),
      ]);
      expect(reminders.first.title, 'Spotify Premium renews today');
      expect(reminders.map((r) => r.id).toSet(), hasLength(2));
    });

    test('trials stop at their first charge', () {
      final sub = subscriptionFixture(isTrial: true);
      final reminders = planAll(sub);
      expect(times(reminders), [
        DateTime(2026, 9, 24, 9),
        DateTime(2026, 9, 30, 9),
      ]);
      expect(
        reminders.every((r) => r.kind == ReminderKind.trialEnding),
        isTrue,
      );
    });

    test('snooze drops earlier reminders but keeps the next cycle', () {
      final sub = subscriptionFixture().copyWith(
        snoozedUntil: DateTime(2026, 9, 30, 15).toUtc(),
      );
      final reminders = planAll(sub);
      expect(times(reminders), [
        DateTime(2026, 9, 30, 15),
        DateTime(2026, 10, 25, 9),
        DateTime(2026, 10, 31, 9),
      ]);
      expect(reminders.map((r) => r.kind), [
        ReminderKind.snoozed,
        ReminderKind.renewal,
        ReminderKind.renewal,
      ]);
    });

    test('a custom period without days plans only the first cycle', () {
      final sub = subscriptionFixture(period: BillingPeriod.customDays);
      expect(times(planAll(sub)), [
        DateTime(2026, 9, 24, 9),
        DateTime(2026, 9, 30, 9),
      ]);
    });

    test('the whole plan is capped well under the alarm limit', () {
      final subs = [
        for (var i = 0; i < 100; i++)
          subscriptionFixture(
            id: 'sub-$i',
            nextBillingDate: CalendarDate(2026, 10, 1).addDays(i % 28),
            reminderOffsets: const [7, 3, 1, 0],
          ),
      ];
      final reminders = planner.plan(
        subscriptions: subs,
        reminderMinutes: nineAm,
        now: now,
      );
      expect(reminders, hasLength(ReminderPlanner.maxReminders));
      expect(ReminderPlanner.maxReminders, lessThan(500));
      expect(reminders.map((r) => r.id).toSet(), hasLength(reminders.length));
      final last = reminders.last.fireAt;
      final all = [
        for (final sub in subs) ...planAll(sub),
      ];
      expect(all.where((r) => r.fireAt.isBefore(last)).length, lessThan(300));
    });

    test('content is built only for reminders that survive the cap', () {
      var built = 0;
      final counting = ReminderPlanner(
        content: (subscription, {required fireDay}) {
          built++;
          return ReminderContent.forSubscription(
            subscription,
            fireDay: fireDay,
          );
        },
      );
      final subs = [
        for (var i = 0; i < 200; i++)
          subscriptionFixture(
            id: 'sub-$i',
            nextBillingDate: CalendarDate(2026, 10, 1).addDays(i % 28),
            reminderOffsets: const [7, 3, 1, 0],
          ),
      ];

      final reminders = counting.plan(
        subscriptions: subs,
        reminderMinutes: nineAm,
        now: now,
      );

      expect(reminders, hasLength(ReminderPlanner.maxReminders));
      expect(built, lessThanOrEqualTo(ReminderPlanner.maxReminders));
      expect(
        reminders,
        planner.plan(subscriptions: subs, reminderMinutes: nineAm, now: now),
      );
    });
  });
}
