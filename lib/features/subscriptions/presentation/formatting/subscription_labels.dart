import 'package:lapse/core/domain/calendar_date.dart';
import 'package:lapse/core/domain/urgency.dart';
import 'package:lapse/core/formatting/date_labels.dart';
import 'package:lapse/core/formatting/money_formatter.dart';
import 'package:lapse/features/subscriptions/domain/entities/billing_period.dart';
import 'package:lapse/features/subscriptions/domain/entities/subscription.dart';

String periodLabel(BillingPeriod period, {int? customDays}) => switch (period) {
  BillingPeriod.weekly => 'Weekly',
  BillingPeriod.monthly => 'Monthly',
  BillingPeriod.quarterly => 'Quarterly',
  BillingPeriod.yearly => 'Yearly',
  BillingPeriod.customDays => switch (customDays) {
    null || < 1 => 'Custom',
    1 => 'Every day',
    final days => 'Every $days days',
  },
};

String perPeriodLabel(BillingPeriod period, {int? customDays}) =>
    switch (period) {
      BillingPeriod.weekly => '/week',
      BillingPeriod.monthly => '/month',
      BillingPeriod.quarterly => '/quarter',
      BillingPeriod.yearly => '/year',
      BillingPeriod.customDays => switch (customDays) {
        null || < 1 => '/cycle',
        1 => '/day',
        final days => '/$days days',
      },
    };

String metaLabel(Subscription s) {
  final price = formatMoney(s.price);
  if (s.isTrial) return '$price after trial';
  return '$price · ${periodLabel(s.period, customDays: s.customDays)}';
}

String dueLabel(Subscription s, CalendarDate today) {
  if (s.nextBillingDate.isBefore(today)) return 'Due';
  return relativeDueLabel(s.nextBillingDate, today);
}

Urgency urgencyOf(Subscription s, CalendarDate today) =>
    Urgency.fromDaysLeft(today.daysUntil(s.nextBillingDate));

final _scheme = RegExp('^[a-zA-Z][a-zA-Z0-9+.-]*://');

String prettyUrl(String url) {
  final trimmed = url.trim();
  if (trimmed.isEmpty) return trimmed;
  final withScheme = _scheme.hasMatch(trimmed) ? trimmed : 'https://$trimmed';
  final uri = Uri.tryParse(withScheme);
  if (uri == null || uri.host.isEmpty) {
    return _stripTrailingSlash(trimmed.replaceFirst(_scheme, ''));
  }
  final host = uri.host.startsWith('www.') ? uri.host.substring(4) : uri.host;
  return _stripTrailingSlash('$host${uri.path}');
}

String _stripTrailingSlash(String value) {
  var result = value;
  while (result.endsWith('/')) {
    result = result.substring(0, result.length - 1);
  }
  return result;
}

String reminderSummary(List<int> offsets) {
  final unique = offsets.where((o) => o >= 0).toSet().toList()
    ..sort((a, b) => b.compareTo(a));
  if (unique.isEmpty) return 'Off';
  final onTheDay = unique.remove(0);
  if (unique.isEmpty) return 'On the day';
  final before = _daysBefore(unique);
  if (!onTheDay) return before;
  return unique.length == 1
      ? '$before and on the day'
      : '$before, and on the day';
}

String _daysBefore(List<int> days) {
  String unit(int value) => value == 1 ? 'day' : 'days';
  if (days.length == 1) return '${days.single} ${unit(days.single)} before';
  if (days.length == 2) {
    final first = days.first;
    final last = days.last;
    return '$first ${unit(first)} and $last ${unit(last)} before';
  }
  final last = days.last;
  final leading = days.take(days.length - 1).join(', ');
  return '$leading and $last ${unit(last)} before';
}

String greetingFor(DateTime now) {
  final hour = now.hour;
  if (hour >= 5 && hour <= 11) return 'Good morning';
  if (hour >= 12 && hour <= 16) return 'Good afternoon';
  return 'Good evening';
}

String cancelledLabel(Subscription s) {
  final cancelledAt = s.cancelledAt;
  if (cancelledAt == null) return 'Cancelled';
  final date = CalendarDate.fromDateTime(cancelledAt.toLocal());
  return 'Cancelled ${shortDateLabel(date)}';
}

String spokenAmountLabel(Subscription s) {
  final period = periodLabel(s.period, customDays: s.customDays);
  return '${formatMoney(s.price)} ${period.toLowerCase()}';
}

String spokenDueLabel(Subscription s, CalendarDate today) {
  final diff = today.daysUntil(s.nextBillingDate);
  if (diff < 0) return 'payment due';
  final relative = relativeDueLabel(s.nextBillingDate, today);
  if (diff < 7) return 'charges ${relative.toLowerCase()}';
  return 'charges on $relative';
}

String spokenCancelledLabel(Subscription s) {
  final cancelledAt = s.cancelledAt;
  if (cancelledAt == null) return '';
  final date = CalendarDate.fromDateTime(cancelledAt.toLocal());
  return 'since ${shortDateLabel(date)}';
}
