import 'package:intl/intl.dart';
import 'package:lapse/core/domain/calendar_date.dart';

final _monthDay = DateFormat('MMM d', 'en_US');
final _full = DateFormat('EEE, d MMM y', 'en_US');
final _short = DateFormat('d MMM', 'en_US');
final _dayDate = DateFormat('EEE, d MMM', 'en_US');

String relativeDueLabel(CalendarDate date, CalendarDate today) {
  final diff = today.daysUntil(date);
  if (diff == 0) return 'Today';
  if (diff == 1) return 'Tomorrow';
  if (diff == -1) return 'Yesterday';
  if (diff < 0) return '${-diff} days ago';
  if (diff < 7) return 'In $diff days';
  return _monthDay.format(date.toDateTime());
}

String fullDateLabel(CalendarDate date) => _full.format(date.toDateTime());

String shortDateLabel(CalendarDate date) => _short.format(date.toDateTime());

String dayDateLabel(CalendarDate date) => _dayDate.format(date.toDateTime());
