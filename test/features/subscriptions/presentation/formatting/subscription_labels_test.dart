import 'package:flutter_test/flutter_test.dart';
import 'package:lapse/core/domain/calendar_date.dart';
import 'package:lapse/core/domain/urgency.dart';
import 'package:lapse/features/subscriptions/domain/entities/billing_period.dart';
import 'package:lapse/features/subscriptions/presentation/formatting/subscription_labels.dart';

import '../../../../helpers/subscription_fixtures.dart';

void main() {
  final today = CalendarDate(2026, 9, 19);

  group('periodLabel', () {
    test('named periods', () {
      expect(periodLabel(BillingPeriod.weekly), 'Weekly');
      expect(periodLabel(BillingPeriod.monthly), 'Monthly');
      expect(periodLabel(BillingPeriod.quarterly), 'Quarterly');
      expect(periodLabel(BillingPeriod.yearly), 'Yearly');
    });

    test('custom days', () {
      expect(
        periodLabel(BillingPeriod.customDays, customDays: 45),
        'Every 45 days',
      );
      expect(periodLabel(BillingPeriod.customDays, customDays: 1), 'Every day');
      expect(periodLabel(BillingPeriod.customDays), 'Custom');
    });
  });

  group('perPeriodLabel', () {
    test('named periods', () {
      expect(perPeriodLabel(BillingPeriod.weekly), '/week');
      expect(perPeriodLabel(BillingPeriod.monthly), '/month');
      expect(perPeriodLabel(BillingPeriod.quarterly), '/quarter');
      expect(perPeriodLabel(BillingPeriod.yearly), '/year');
    });

    test('custom days', () {
      expect(
        perPeriodLabel(BillingPeriod.customDays, customDays: 45),
        '/45 days',
      );
      expect(perPeriodLabel(BillingPeriod.customDays, customDays: 1), '/day');
      expect(perPeriodLabel(BillingPeriod.customDays), '/cycle');
    });
  });

  test('metaLabel shows price and period, or the after-trial price', () {
    expect(metaLabel(subscriptionFixture()), 'Rs 299 · Monthly');
    expect(
      metaLabel(
        subscriptionFixture(
          priceMinor: 999,
          currency: 'USD',
          period: BillingPeriod.customDays,
          customDays: 45,
        ),
      ),
      r'$9.99 · Every 45 days',
    );
    expect(
      metaLabel(subscriptionFixture(priceMinor: 64900, isTrial: true)),
      'Rs 649 after trial',
    );
  });

  group('dueLabel', () {
    String due(CalendarDate date) =>
        dueLabel(subscriptionFixture(nextBillingDate: date), today);

    test('relative labels for today and later', () {
      expect(due(today), 'Today');
      expect(due(today.addDays(1)), 'Tomorrow');
      expect(due(today.addDays(3)), 'In 3 days');
      expect(due(CalendarDate(2026, 10, 24)), 'Oct 24');
    });

    test('overdue shows Due', () {
      expect(due(today.addDays(-1)), 'Due');
      expect(due(today.addDays(-30)), 'Due');
    });
  });

  test('urgencyOf follows days left', () {
    Urgency urgency(int days) => urgencyOf(
      subscriptionFixture(nextBillingDate: today.addDays(days)),
      today,
    );

    expect(urgency(-2), Urgency.urgent);
    expect(urgency(0), Urgency.urgent);
    expect(urgency(1), Urgency.urgent);
    expect(urgency(2), Urgency.warning);
    expect(urgency(3), Urgency.warning);
    expect(urgency(4), Urgency.normal);
  });

  group('prettyUrl', () {
    test('drops scheme, www and trailing slash', () {
      expect(
        prettyUrl('https://www.netflix.com/cancelplan'),
        'netflix.com/cancelplan',
      );
      expect(prettyUrl('http://spotify.com/account/'), 'spotify.com/account');
      expect(prettyUrl('https://www.youtube.com/'), 'youtube.com');
      expect(prettyUrl('https://example.com'), 'example.com');
    });

    test('keeps the query and fragment out', () {
      expect(
        prettyUrl('https://www.hulu.com/account?tab=cancel#top'),
        'hulu.com/account',
      );
    });

    test('handles text without a scheme and blanks', () {
      expect(prettyUrl('www.disneyplus.com/account'), 'disneyplus.com/account');
      expect(prettyUrl('  netflix.com/  '), 'netflix.com');
      expect(prettyUrl(''), '');
    });

    test('keeps subdomains other than www', () {
      expect(
        prettyUrl('https://account.apple.com/subscriptions'),
        'account.apple.com/subscriptions',
      );
    });
  });

  group('reminderSummary', () {
    test('off and on the day', () {
      expect(reminderSummary(const []), 'Off');
      expect(reminderSummary(const [0]), 'On the day');
    });

    test('single offsets', () {
      expect(reminderSummary(const [1]), '1 day before');
      expect(reminderSummary(const [7]), '7 days before');
    });

    test('two offsets name both units', () {
      expect(reminderSummary(const [7, 1]), '7 days and 1 day before');
      expect(reminderSummary(const [1, 7]), '7 days and 1 day before');
      expect(reminderSummary(const [3, 2]), '3 days and 2 days before');
    });

    test('three or more offsets list the numbers', () {
      expect(reminderSummary(const [7, 3, 1]), '7, 3 and 1 day before');
      expect(reminderSummary(const [14, 7, 3]), '14, 7 and 3 days before');
    });

    test('mixes in on the day', () {
      expect(reminderSummary(const [0, 1]), '1 day before and on the day');
      expect(
        reminderSummary(const [7, 1, 0]),
        '7 days and 1 day before, and on the day',
      );
    });

    test('ignores duplicates and negatives', () {
      expect(reminderSummary(const [1, 1, -3]), '1 day before');
      expect(reminderSummary(const [-1]), 'Off');
    });
  });

  test('greetingFor splits the day at 5, 12 and 17', () {
    String greet(int hour, [int minute = 0]) =>
        greetingFor(DateTime(2026, 9, 19, hour, minute));

    expect(greet(0), 'Good evening');
    expect(greet(4, 59), 'Good evening');
    expect(greet(5), 'Good morning');
    expect(greet(11, 59), 'Good morning');
    expect(greet(12), 'Good afternoon');
    expect(greet(16, 59), 'Good afternoon');
    expect(greet(17), 'Good evening');
    expect(greet(23), 'Good evening');
  });

  test('cancelledLabel shows the local cancel date when known', () {
    final sub = subscriptionFixture();

    expect(cancelledLabel(sub), 'Cancelled');
    expect(
      cancelledLabel(sub.copyWith(cancelledAt: DateTime(2026, 9, 12, 10))),
      'Cancelled 12 Sep',
    );
  });
}
