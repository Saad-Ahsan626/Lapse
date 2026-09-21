import 'package:intl/intl.dart';
import 'package:lapse/core/domain/calendar_date.dart';
import 'package:lapse/core/formatting/money_formatter.dart';
import 'package:lapse/features/subscriptions/domain/entities/subscription.dart';
import 'package:lapse/features/subscriptions/presentation/links/cancel_links.dart';

abstract final class ReminderContent {
  static final _chargeDay = DateFormat('EEE, d MMM', 'en_US');

  static ({String title, String body}) forSubscription(
    Subscription subscription, {
    required CalendarDate fireDay,
  }) {
    final chargeDay = subscription.nextBillingDate;
    final rawDays = fireDay.daysUntil(chargeDay);
    final days = rawDays < 0 ? 0 : rawDays;
    final date = _chargeDay.format(chargeDay.toDateTime());
    final amount = formatMoney(subscription.price);
    final when = days == 0 ? 'today' : 'on $date';
    final action = cancelUriFor(subscription) == null
        ? 'Tap to see details.'
        : 'Tap to cancel.';
    final name = subscription.name;
    if (subscription.isTrial) {
      return (
        title: '$name trial ends ${_relative(days, date)}',
        body: "You'll be charged $amount $when. $action",
      );
    }
    return (
      title: '$name renews ${_relative(days, date)}',
      body: '$amount $when. $action',
    );
  }

  static String _relative(int days, String date) {
    if (days == 0) return 'today';
    if (days == 1) return 'tomorrow';
    if (days < 7) return 'in $days days';
    return 'on $date';
  }
}
