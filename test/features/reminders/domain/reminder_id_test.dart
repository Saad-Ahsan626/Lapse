import 'package:flutter_test/flutter_test.dart';
import 'package:lapse/core/domain/calendar_date.dart';
import 'package:lapse/features/reminders/domain/reminder_id.dart';

void main() {
  final day = CalendarDate(2026, 9, 30);

  test('is stable across calls', () {
    expect(reminderId('sub-1', day), reminderId('sub-1', day));
    expect(
      reminderId('sub-1', CalendarDate(2026, 9, 30)),
      reminderId('sub-1', day),
    );
  });

  test('matches FNV-1a 32-bit masked to 31 bits', () {
    expect(
      reminderId('', CalendarDate(2026, 1, 1)),
      _reference('|2026-01-01'),
    );
    expect(reminderId('sub-1', day), _reference('sub-1|2026-09-30'));
    expect(
      reminderId('a8f0c1e2-uuid', CalendarDate(2024, 2, 29)),
      _reference('a8f0c1e2-uuid|2024-02-29'),
    );
  });

  test('differs per subscription and per day', () {
    expect(reminderId('sub-1', day), isNot(reminderId('sub-2', day)));
    expect(
      reminderId('sub-1', day),
      isNot(reminderId('sub-1', day.addDays(1))),
    );
  });

  test('is always in 0 < id < 2^31 and unique over a year', () {
    final ids = <int>{};
    var date = CalendarDate(2026, 1, 1);
    for (var i = 0; i < 366; i++) {
      for (final sub in ['sub-1', 'sub-2', 'netflix', 'abc-123']) {
        final id = reminderId(sub, date);
        expect(id, greaterThan(0));
        expect(id, lessThan(1 << 31));
        ids.add(id);
      }
      date = date.addDays(1);
    }
    expect(ids, hasLength(366 * 4));
  });
}

int _reference(String asciiInput) {
  var hash = 2166136261;
  for (final unit in asciiInput.codeUnits) {
    hash = ((hash ^ unit) * 16777619) % 4294967296;
  }
  final id = hash % 2147483648;
  return id == 0 ? 1 : id;
}
