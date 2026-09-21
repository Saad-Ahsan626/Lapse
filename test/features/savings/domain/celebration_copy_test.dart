import 'package:flutter_test/flutter_test.dart';
import 'package:lapse/core/domain/calendar_date.dart';
import 'package:lapse/core/domain/money.dart';
import 'package:lapse/features/savings/domain/celebration_copy.dart';

import '../../../helpers/subscription_fixtures.dart';

void main() {
  final icloud = subscriptionFixture(name: 'iCloud+ 200GB', priceMinor: 64900);
  final netflix = subscriptionFixture(
    name: 'Netflix',
    priceMinor: 64900,
    isTrial: true,
    nextBillingDate: CalendarDate(2026, 9, 19),
  );

  group('headline', () {
    test('normal', () {
      expect(CelebrationCopy.headline(icloud), 'iCloud+ 200GB cancelled');
    });

    test('trial', () {
      expect(CelebrationCopy.headline(netflix), 'Netflix trial cancelled');
    });

    test('trial name already ending in trial is not doubled', () {
      final s = netflix.copyWith(name: 'Canva Pro Trial');

      expect(CelebrationCopy.headline(s), 'Canva Pro Trial cancelled');
    });
  });

  group('body', () {
    test('normal with the Nth line', () {
      expect(
        CelebrationCopy.body(icloud, cancelledThisYear: 3),
        "That's your third cancellation this year. "
        'It stays in the Cancelled tab in case you want it back.',
      );
      expect(
        CelebrationCopy.body(icloud, cancelledThisYear: 12),
        startsWith("That's your 12th cancellation this year."),
      );
    });

    test('normal without a count skips the Nth line', () {
      expect(
        CelebrationCopy.body(icloud, cancelledThisYear: 0),
        'It stays in the Cancelled tab in case you want it back.',
      );
    });

    test('trial names the charge it avoids', () {
      expect(
        CelebrationCopy.body(netflix, cancelledThisYear: 3),
        "You won't be charged Rs 649 on Sat, 19 Sep. "
        'It stays in the Cancelled tab in case you want it back.',
      );
    });
  });

  test('ordinal', () {
    const expected = {
      1: 'first',
      2: 'second',
      3: 'third',
      4: 'fourth',
      5: 'fifth',
      6: 'sixth',
      7: 'seventh',
      8: 'eighth',
      9: 'ninth',
      10: 'tenth',
      11: '11th',
      12: '12th',
      13: '13th',
      14: '14th',
      21: '21st',
      22: '22nd',
      23: '23rd',
      24: '24th',
      101: '101st',
      102: '102nd',
      111: '111th',
      112: '112th',
      113: '113th',
    };
    for (final MapEntry(:key, :value) in expected.entries) {
      expect(CelebrationCopy.ordinal(key), value, reason: '$key');
    }
  });

  group('announcement', () {
    test('includes the yearly saving', () {
      expect(
        CelebrationCopy.announcement(icloud, const Money(778800, 'PKR')),
        'iCloud+ 200GB cancelled. Saving Rs 7,788 per year.',
      );
    });

    test('drops the saving when it is zero', () {
      expect(
        CelebrationCopy.announcement(icloud, const Money.zero('PKR')),
        'iCloud+ 200GB cancelled.',
      );
    });

    test('trial headline', () {
      expect(
        CelebrationCopy.announcement(netflix, const Money(778800, 'PKR')),
        'Netflix trial cancelled. Saving Rs 7,788 per year.',
      );
    });
  });
}
