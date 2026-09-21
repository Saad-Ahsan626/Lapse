import 'package:lapse/core/domain/money.dart';
import 'package:lapse/features/subscriptions/domain/entities/subscription.dart';
import 'package:lapse/features/subscriptions/domain/services/billing_engine.dart';

abstract final class CancellationStats {
  static int cancelledThisYear(
    List<Subscription> subscriptions,
    DateTime now,
  ) {
    var count = 0;
    for (final s in subscriptions) {
      final at = s.cancelledAt;
      if (!s.isCancelled || at == null) continue;
      if (at.toLocal().year == now.year) count++;
    }
    return count;
  }

  static Money savedPerYear(
    List<Subscription> subscriptions,
    String currency,
    BillingEngine engine,
  ) {
    var saved = Money.zero(currency);
    for (final s in subscriptions) {
      if (!s.isCancelled || s.price.currency != currency) continue;
      saved += engine.yearlyCost(s);
    }
    return saved;
  }

  static int cancelledCount(List<Subscription> subscriptions, String currency) {
    return subscriptions
        .where((s) => s.isCancelled && s.price.currency == currency)
        .length;
  }
}
