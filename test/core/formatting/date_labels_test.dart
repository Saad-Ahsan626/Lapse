import 'package:flutter_test/flutter_test.dart';
import 'package:lapse/core/domain/calendar_date.dart';
import 'package:lapse/core/formatting/date_labels.dart';

void main() {
  final today = CalendarDate(2026, 9, 19);

  group('relativeDueLabel', () {
    test('near future', () {
      expect(relativeDueLabel(today, today), 'Today');
      expect(relativeDueLabel(today.addDays(1), today), 'Tomorrow');
      expect(relativeDueLabel(today.addDays(2), today), 'In 2 days');
      expect(relativeDueLabel(today.addDays(6), today), 'In 6 days');
    });

    test('a week or more shows the date', () {
      expect(relativeDueLabel(today.addDays(7), today), 'Sep 26');
      expect(relativeDueLabel(CalendarDate(2026, 10, 24), today), 'Oct 24');
    });

    test('past', () {
      expect(relativeDueLabel(today.addDays(-1), today), 'Yesterday');
      expect(relativeDueLabel(today.addDays(-2), today), '2 days ago');
      expect(relativeDueLabel(today.addDays(-30), today), '30 days ago');
    });

    test('across a year change', () {
      expect(
        relativeDueLabel(CalendarDate(2027, 1, 2), CalendarDate(2026, 12, 30)),
        'In 3 days',
      );
      expect(
        relativeDueLabel(CalendarDate(2027, 1, 2), CalendarDate(2026, 12, 20)),
        'Jan 2',
      );
    });
  });

  test('fullDateLabel', () {
    expect(fullDateLabel(today), 'Sat, 19 Sep 2026');
    expect(fullDateLabel(CalendarDate(2027, 1, 2)), 'Sat, 2 Jan 2027');
  });

  test('shortDateLabel', () {
    expect(shortDateLabel(today), '19 Sep');
    expect(shortDateLabel(CalendarDate(2027, 1, 2)), '2 Jan');
  });
}
