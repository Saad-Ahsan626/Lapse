import 'package:lapse/core/domain/calendar_date.dart';
import 'package:lapse/core/domain/money.dart';
import 'package:lapse/features/subscriptions/domain/entities/charge.dart';
import 'package:lapse/features/subscriptions/domain/entities/subscription.dart';
import 'package:lapse/features/subscriptions/domain/services/billing_engine.dart';
import 'package:lapse/features/subscriptions/domain/services/spending_summary.dart';

class SpendingCalculator {
  const SpendingCalculator(this._engine);

  final BillingEngine _engine;

  SpendingSummary summarize({
    required List<Subscription> subscriptions,
    required List<Charge> chargesThisMonth,
    required CalendarDate today,
    required String currency,
  }) {
    final monthStart = CalendarDate(today.year, today.month, 1);
    final monthEnd = CalendarDate(
      today.year,
      today.month,
      CalendarDate.daysInMonth(today.year, today.month),
    );
    var thisMonth = Money.zero(currency);
    var yearly = Money.zero(currency);
    var saved = Money.zero(currency);
    final others = <String, Money>{};

    for (final charge in chargesThisMonth) {
      final date = charge.chargedOn;
      if (charge.amount.currency != currency) continue;
      if (date.isBefore(monthStart) || date.isAfter(monthEnd)) continue;
      thisMonth += charge.amount;
    }

    for (final subscription in subscriptions) {
      final code = subscription.price.currency;
      final cost = _engine.yearlyCost(subscription);
      if (subscription.isCancelled) {
        if (code == currency) saved += cost;
        continue;
      }
      if (code != currency) {
        others[code] = (others[code] ?? Money.zero(code)) + cost;
        continue;
      }
      yearly += cost;
      final due = _engine.occurrencesBetween(subscription, today, monthEnd);
      thisMonth += subscription.price * due.length;
    }

    return SpendingSummary(
      thisMonth: thisMonth,
      yearly: yearly,
      savedPerYear: saved,
      otherCurrencies: Map.unmodifiable(others),
    );
  }
}
