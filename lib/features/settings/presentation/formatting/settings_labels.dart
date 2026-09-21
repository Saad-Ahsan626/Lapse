import 'package:lapse/core/domain/calendar_date.dart';
import 'package:lapse/core/domain/currency_info.dart';
import 'package:lapse/core/formatting/date_labels.dart';

String currencyLabel(String code) {
  final info = currencyInfo(code);
  return info.symbol == info.code ? info.code : '${info.code} · ${info.symbol}';
}

String reminderOffsetsLabel(List<int> offsets) {
  if (offsets.isEmpty) return 'Off';
  final sorted = offsets.toSet().toList()..sort((a, b) => b.compareTo(a));
  return [
    for (final offset in sorted) offset == 0 ? 'Day of' : '${offset}d',
  ].join(', ');
}

String reminderTimeLabel(int minutes) {
  final value = minutes % (24 * 60);
  final hour = value ~/ 60;
  final hour12 = hour % 12 == 0 ? 12 : hour % 12;
  final hh = hour12.toString().padLeft(2, '0');
  final mm = (value % 60).toString().padLeft(2, '0');
  return '$hh:$mm ${hour < 12 ? 'AM' : 'PM'}';
}

String reminderMomentLabel(DateTime fireAt) =>
    '${dayDateLabel(CalendarDate.fromDateTime(fireAt))} · '
    '${reminderTimeLabel(fireAt.hour * 60 + fireAt.minute)}';

String reminderTimeSavedMessage(int minutes) =>
    'Reminder time saved, ${reminderTimeLabel(minutes)}';
