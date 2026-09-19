import 'package:flutter_test/flutter_test.dart';
import 'package:lapse/core/domain/calendar_date.dart';

void main() {
  group('construction', () {
    test('rejects impossible dates', () {
      expect(() => CalendarDate(2026, 0, 1), throwsArgumentError);
      expect(() => CalendarDate(2026, 13, 1), throwsArgumentError);
      expect(() => CalendarDate(2026, 2, 29), throwsArgumentError);
      expect(() => CalendarDate(2026, 4, 31), throwsArgumentError);
      expect(() => CalendarDate(2026, 1, 0), throwsArgumentError);
    });

    test('accepts Feb 29 in leap years', () {
      expect(CalendarDate(2028, 2, 29).day, 29);
    });

    test('fromDateTime drops the time', () {
      expect(
        CalendarDate.fromDateTime(DateTime(2026, 9, 19, 23, 59)),
        CalendarDate(2026, 9, 19),
      );
    });
  });

  group('parse / toIso', () {
    test('round trips', () {
      final date = CalendarDate(2026, 3, 7);
      expect(date.toIso(), '2026-03-07');
      expect(CalendarDate.parse('2026-03-07'), date);
      expect(date.toString(), '2026-03-07');
    });

    test('rejects malformed input', () {
      expect(() => CalendarDate.parse('2026-3-7'), throwsFormatException);
      expect(() => CalendarDate.parse('07/03/2026'), throwsFormatException);
      expect(() => CalendarDate.parse(''), throwsFormatException);
    });

    test('toDateTime is local midnight', () {
      expect(CalendarDate(2026, 9, 19).toDateTime(), DateTime(2026, 9, 19));
    });
  });

  group('leap years', () {
    test('follows the Gregorian rules', () {
      expect(CalendarDate.isLeapYear(2024), isTrue);
      expect(CalendarDate.isLeapYear(2026), isFalse);
      expect(CalendarDate.isLeapYear(2000), isTrue);
      expect(CalendarDate.isLeapYear(2100), isFalse);
    });

    test('daysInMonth', () {
      expect(CalendarDate.daysInMonth(2026, 1), 31);
      expect(CalendarDate.daysInMonth(2026, 2), 28);
      expect(CalendarDate.daysInMonth(2028, 2), 29);
      expect(CalendarDate.daysInMonth(2026, 4), 30);
      expect(CalendarDate.daysInMonth(2026, 12), 31);
    });
  });

  group('addDays', () {
    test('crosses month and year ends', () {
      expect(CalendarDate(2026, 1, 31).addDays(1), CalendarDate(2026, 2, 1));
      expect(CalendarDate(2026, 12, 31).addDays(1), CalendarDate(2027, 1, 1));
      expect(CalendarDate(2026, 3, 1).addDays(-1), CalendarDate(2026, 2, 28));
      expect(CalendarDate(2028, 3, 1).addDays(-1), CalendarDate(2028, 2, 29));
    });

    test('is not shifted by daylight-saving changes', () {
      expect(CalendarDate(2026, 3, 28).addDays(2), CalendarDate(2026, 3, 30));
      expect(
        CalendarDate(2026, 10, 24).addDays(2),
        CalendarDate(2026, 10, 26),
      );
      expect(CalendarDate(2026, 3, 8).addDays(1), CalendarDate(2026, 3, 9));
    });
  });

  group('addMonths', () {
    test('clamps to the end of shorter months', () {
      expect(
        CalendarDate(2026, 1, 31).addMonths(1),
        CalendarDate(2026, 2, 28),
      );
      expect(
        CalendarDate(2028, 1, 31).addMonths(1),
        CalendarDate(2028, 2, 29),
      );
      expect(
        CalendarDate(2026, 3, 31).addMonths(1),
        CalendarDate(2026, 4, 30),
      );
    });

    test('returns to the anchor day when the month allows it', () {
      final feb = CalendarDate(2026, 2, 28);
      expect(feb.addMonths(1, anchorDay: 31), CalendarDate(2026, 3, 31));
      expect(feb.addMonths(1, anchorDay: 30), CalendarDate(2026, 3, 30));
      expect(feb.addMonths(1, anchorDay: 29), CalendarDate(2026, 3, 29));
      expect(feb.addMonths(1), CalendarDate(2026, 3, 28));
    });

    test('crosses years in both directions', () {
      expect(
        CalendarDate(2026, 11, 15).addMonths(3),
        CalendarDate(2027, 2, 15),
      );
      expect(
        CalendarDate(2026, 1, 15).addMonths(-1),
        CalendarDate(2025, 12, 15),
      );
      expect(
        CalendarDate(2028, 2, 29).addMonths(12),
        CalendarDate(2029, 2, 28),
      );
    });
  });

  group('comparison', () {
    final a = CalendarDate(2026, 9, 19);
    final b = CalendarDate(2026, 10, 1);

    test('daysUntil is signed', () {
      expect(a.daysUntil(b), 12);
      expect(b.daysUntil(a), -12);
      expect(a.daysUntil(a), 0);
      expect(
        CalendarDate(2026, 1, 1).daysUntil(CalendarDate(2027, 1, 1)),
        365,
      );
    });

    test('isBefore / isAfter / compareTo', () {
      expect(a.isBefore(b), isTrue);
      expect(b.isAfter(a), isTrue);
      expect(a.isBefore(a), isFalse);
      expect(a.isAfter(a), isFalse);
      expect([b, a]..sort(), [a, b]);
    });

    test('equality and hashCode', () {
      expect(CalendarDate(2026, 9, 19), a);
      expect(CalendarDate(2026, 9, 19).hashCode, a.hashCode);
      expect(a == b, isFalse);
    });
  });
}
