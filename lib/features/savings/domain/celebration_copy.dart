import 'package:lapse/core/domain/money.dart';
import 'package:lapse/core/formatting/date_labels.dart';
import 'package:lapse/core/formatting/money_formatter.dart';
import 'package:lapse/features/subscriptions/domain/entities/subscription.dart';

abstract final class CelebrationCopy {
  static const _stays =
      'It stays in the Cancelled tab in case you want it back.';

  static const _words = [
    'first',
    'second',
    'third',
    'fourth',
    'fifth',
    'sixth',
    'seventh',
    'eighth',
    'ninth',
    'tenth',
  ];

  static String headline(Subscription s) {
    final name = s.name.trim();
    if (!s.isTrial) return '$name cancelled';
    if (name.toLowerCase().endsWith('trial')) return '$name cancelled';
    return '$name trial cancelled';
  }

  static String body(Subscription s, {required int cancelledThisYear}) {
    if (s.isTrial) {
      final price = formatMoney(s.price);
      final date = dayDateLabel(s.nextBillingDate);
      return "You won't be charged $price on $date. $_stays";
    }
    if (cancelledThisYear < 1) return _stays;
    final nth = ordinal(cancelledThisYear);
    return "That's your $nth cancellation this year. $_stays";
  }

  static String ordinal(int n) {
    if (n >= 1 && n <= _words.length) return _words[n - 1];
    final lastTwo = n.abs() % 100;
    if (lastTwo >= 11 && lastTwo <= 13) return '${n}th';
    final suffix = switch (n.abs() % 10) {
      1 => 'st',
      2 => 'nd',
      3 => 'rd',
      _ => 'th',
    };
    return '$n$suffix';
  }

  static String announcement(Subscription s, Money saved) {
    final head = headline(s);
    if (!saved.isPositive) return '$head.';
    return '$head. Saving ${formatMoney(saved)} per year.';
  }
}
