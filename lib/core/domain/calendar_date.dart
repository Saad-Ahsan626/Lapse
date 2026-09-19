import 'dart:math' as math;

import 'package:flutter/foundation.dart';

@immutable
class CalendarDate implements Comparable<CalendarDate> {
  CalendarDate(this.year, this.month, this.day) {
    if (month < 1 || month > 12) {
      throw ArgumentError.value(month, 'month', 'must be 1–12');
    }
    if (day < 1 || day > daysInMonth(year, month)) {
      throw ArgumentError.value(day, 'day', 'out of range for $year-$month');
    }
  }

  factory CalendarDate.fromDateTime(DateTime dateTime) =>
      CalendarDate(dateTime.year, dateTime.month, dateTime.day);

  factory CalendarDate.parse(String iso) {
    final match = _isoPattern.firstMatch(iso);
    if (match == null) throw FormatException('Invalid calendar date', iso);
    return CalendarDate(
      int.parse(match.group(1)!),
      int.parse(match.group(2)!),
      int.parse(match.group(3)!),
    );
  }

  static final _isoPattern = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');
  static const _monthLengths = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];

  final int year;
  final int month;
  final int day;

  static bool isLeapYear(int year) =>
      year % 4 == 0 && (year % 100 != 0 || year % 400 == 0);

  static int daysInMonth(int year, int month) =>
      month == 2 && isLeapYear(year) ? 29 : _monthLengths[month - 1];

  CalendarDate addDays(int days) {
    final shifted = _utc.add(Duration(days: days));
    return CalendarDate(shifted.year, shifted.month, shifted.day);
  }

  CalendarDate addMonths(int months, {int? anchorDay}) {
    final monthIndex = year * 12 + (month - 1) + months;
    final newYear = monthIndex ~/ 12;
    final newMonth = monthIndex % 12 + 1;
    final targetDay = anchorDay ?? day;
    return CalendarDate(
      newYear,
      newMonth,
      math.min(targetDay, daysInMonth(newYear, newMonth)),
    );
  }

  int daysUntil(CalendarDate other) => other._utc.difference(_utc).inDays;

  bool isBefore(CalendarDate other) => compareTo(other) < 0;

  bool isAfter(CalendarDate other) => compareTo(other) > 0;

  String toIso() =>
      '${year.toString().padLeft(4, '0')}-'
      '${month.toString().padLeft(2, '0')}-'
      '${day.toString().padLeft(2, '0')}';

  DateTime toDateTime() => DateTime(year, month, day);

  DateTime get _utc => DateTime.utc(year, month, day);

  int get _sortKey => year * 10000 + month * 100 + day;

  @override
  int compareTo(CalendarDate other) => _sortKey.compareTo(other._sortKey);

  @override
  bool operator ==(Object other) =>
      other is CalendarDate &&
      other.year == year &&
      other.month == month &&
      other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  String toString() => toIso();
}
