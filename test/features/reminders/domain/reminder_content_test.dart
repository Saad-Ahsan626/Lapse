import 'package:flutter_test/flutter_test.dart';
import 'package:lapse/core/domain/calendar_date.dart';
import 'package:lapse/features/reminders/domain/reminder_content.dart';
import 'package:lapse/features/subscriptions/domain/entities/subscription.dart';

import '../../../helpers/subscription_fixtures.dart';

void main() {
  final trialCharge = CalendarDate(2026, 9, 19);
  final renewalCharge = CalendarDate(2026, 9, 21);

  Subscription trial({String? cancelUrl = 'netflix.com/cancel'}) =>
      subscriptionFixture(
        name: 'Netflix',
        priceMinor: 64900,
        isTrial: true,
        nextBillingDate: trialCharge,
        cancelUrl: cancelUrl,
      );

  Subscription renewal({
    String? cancelUrl = 'https://spotify.com/account',
    int priceMinor = 29900,
    String currency = 'PKR',
  }) => subscriptionFixture(
    name: 'Spotify',
    priceMinor: priceMinor,
    currency: currency,
    nextBillingDate: renewalCharge,
    cancelUrl: cancelUrl,
  );

  group('trial wording', () {
    const charged = "You'll be charged Rs 649 on Sat, 19 Sep. Tap to cancel.";
    final cases = <int, (String, String)>{
      0: (
        'Netflix trial ends today',
        "You'll be charged Rs 649 today. Tap to cancel.",
      ),
      1: ('Netflix trial ends tomorrow', charged),
      2: ('Netflix trial ends in 2 days', charged),
      3: ('Netflix trial ends in 3 days', charged),
      6: ('Netflix trial ends in 6 days', charged),
      7: ('Netflix trial ends on Sat, 19 Sep', charged),
      10: ('Netflix trial ends on Sat, 19 Sep', charged),
    };
    for (final entry in cases.entries) {
      test('${entry.key} days before', () {
        final content = ReminderContent.forSubscription(
          trial(),
          fireDay: trialCharge.addDays(-entry.key),
        );
        expect(content.title, entry.value.$1);
        expect(content.body, entry.value.$2);
      });
    }
  });

  group('renewal wording', () {
    const onDay = 'Rs 299 on Mon, 21 Sep. Tap to cancel.';
    final cases = <int, (String, String)>{
      0: ('Spotify renews today', 'Rs 299 today. Tap to cancel.'),
      1: ('Spotify renews tomorrow', onDay),
      2: ('Spotify renews in 2 days', onDay),
      3: ('Spotify renews in 3 days', onDay),
      6: ('Spotify renews in 6 days', onDay),
      7: ('Spotify renews on Mon, 21 Sep', onDay),
      10: ('Spotify renews on Mon, 21 Sep', onDay),
    };
    for (final entry in cases.entries) {
      test('${entry.key} days before', () {
        final content = ReminderContent.forSubscription(
          renewal(),
          fireDay: renewalCharge.addDays(-entry.key),
        );
        expect(content.title, entry.value.$1);
        expect(content.body, entry.value.$2);
      });
    }
  });

  test('negative days are treated as today', () {
    final content = ReminderContent.forSubscription(
      renewal(),
      fireDay: renewalCharge.addDays(2),
    );
    expect(content.title, 'Spotify renews today');
    expect(content.body, 'Rs 299 today. Tap to cancel.');
    final trialContent = ReminderContent.forSubscription(
      trial(),
      fireDay: trialCharge.addDays(1),
    );
    expect(trialContent.title, 'Netflix trial ends today');
    expect(
      trialContent.body,
      "You'll be charged Rs 649 today. Tap to cancel.",
    );
  });

  group('without a cancel link', () {
    test('trial points to details', () {
      final content = ReminderContent.forSubscription(
        trial(cancelUrl: null),
        fireDay: trialCharge.addDays(-1),
      );
      expect(
        content.body,
        "You'll be charged Rs 649 on Sat, 19 Sep. Tap to see details.",
      );
    });

    test('renewal points to details', () {
      final content = ReminderContent.forSubscription(
        renewal(cancelUrl: '   '),
        fireDay: renewalCharge,
      );
      expect(content.body, 'Rs 299 today. Tap to see details.');
    });

    test('unsupported scheme counts as no link', () {
      final content = ReminderContent.forSubscription(
        renewal(cancelUrl: 'ftp://spotify.com'),
        fireDay: renewalCharge,
      );
      expect(content.body, endsWith('Tap to see details.'));
    });
  });

  group('amounts', () {
    test('big amounts are grouped', () {
      final content = ReminderContent.forSubscription(
        renewal(priceMinor: 123456789),
        fireDay: renewalCharge.addDays(-1),
      );
      expect(content.body, 'Rs 1,234,567.89 on Mon, 21 Sep. Tap to cancel.');
    });

    test('dollars', () {
      final content = ReminderContent.forSubscription(
        renewal(priceMinor: 999, currency: 'USD'),
        fireDay: renewalCharge,
      );
      expect(content.body, r'$9.99 today. Tap to cancel.');
    });

    test('euros', () {
      final content = ReminderContent.forSubscription(
        renewal(priceMinor: 1250, currency: 'EUR'),
        fireDay: renewalCharge.addDays(-3),
      );
      expect(content.body, '€12.50 on Mon, 21 Sep. Tap to cancel.');
    });

    test('letter symbols get a space', () {
      final content = ReminderContent.forSubscription(
        renewal(priceMinor: 3675, currency: 'AED'),
        fireDay: renewalCharge,
      );
      expect(content.body, 'AED 36.75 today. Tap to cancel.');
    });
  });

  test('date crosses a year boundary', () {
    final sub = subscriptionFixture(
      name: 'iCloud+',
      priceMinor: 25000,
      nextBillingDate: CalendarDate(2027, 1, 1),
      cancelUrl: 'apple.com',
    );
    final content = ReminderContent.forSubscription(
      sub,
      fireDay: CalendarDate(2026, 12, 25),
    );
    expect(content.title, 'iCloud+ renews on Fri, 1 Jan');
    expect(content.body, 'Rs 250 on Fri, 1 Jan. Tap to cancel.');
  });
}
