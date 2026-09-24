import 'package:lapse/core/domain/calendar_date.dart';
import 'package:lapse/core/domain/clock.dart';
import 'package:lapse/core/domain/money.dart';
import 'package:lapse/features/subscriptions/domain/entities/billing_period.dart';
import 'package:lapse/features/subscriptions/domain/entities/charge.dart';
import 'package:lapse/features/subscriptions/domain/entities/subscription.dart';
import 'package:lapse/features/subscriptions/domain/services/roll_over_result.dart';

class BillingEngine {
  const BillingEngine();

  static const maxIterations = 1000;
  static const maxRollOverPeriods = 100000;
  static const daysPerYear = 365;

  CalendarDate nextDate(
    CalendarDate from,
    BillingPeriod period, {
    required int anchorDay,
    int? customDays,
  }) => switch (period) {
    BillingPeriod.weekly => from.addDays(7),
    BillingPeriod.monthly => from.addMonths(1, anchorDay: anchorDay),
    BillingPeriod.quarterly => from.addMonths(3, anchorDay: anchorDay),
    BillingPeriod.yearly => from.addMonths(12, anchorDay: anchorDay),
    BillingPeriod.customDays => from.addDays(_requireCustomDays(customDays)),
  };

  CalendarDate previousDate(
    CalendarDate from,
    BillingPeriod period, {
    required int anchorDay,
    int? customDays,
  }) => switch (period) {
    BillingPeriod.weekly => from.addDays(-7),
    BillingPeriod.monthly => from.addMonths(-1, anchorDay: anchorDay),
    BillingPeriod.quarterly => from.addMonths(-3, anchorDay: anchorDay),
    BillingPeriod.yearly => from.addMonths(-12, anchorDay: anchorDay),
    BillingPeriod.customDays => from.addDays(-_requireCustomDays(customDays)),
  };

  CalendarDate nextDateFor(Subscription subscription) => nextDate(
    subscription.nextBillingDate,
    subscription.period,
    anchorDay: subscription.anchorDay,
    customDays: subscription.customDays,
  );

  RollOverResult rollOver(
    Subscription subscription,
    CalendarDate today, {
    required IdGenerator newId,
  }) {
    if (subscription.isCancelled) {
      return RollOverResult(subscription: subscription);
    }
    var current = subscription;
    final charges = <Charge>[];
    for (var i = 0; i < maxRollOverPeriods; i++) {
      if (!current.nextBillingDate.isBefore(today)) break;
      charges.add(
        Charge(
          id: newId(),
          subscriptionId: current.id,
          amount: current.price,
          chargedOn: current.nextBillingDate,
        ),
      );
      current = current.copyWith(
        nextBillingDate: nextDateFor(current),
        isTrial: false,
      );
    }
    return RollOverResult(subscription: current, charges: charges);
  }

  List<CalendarDate> occurrencesBetween(
    Subscription subscription,
    CalendarDate from,
    CalendarDate to,
  ) {
    if (subscription.isCancelled) return const [];
    final dates = <CalendarDate>[];
    var date = subscription.nextBillingDate;
    for (var i = 0; i < maxIterations && !date.isAfter(to); i++) {
      if (!date.isBefore(from)) dates.add(date);
      date = nextDate(
        date,
        subscription.period,
        anchorDay: subscription.anchorDay,
        customDays: subscription.customDays,
      );
    }
    return dates;
  }

  Money yearlyCost(Subscription subscription) {
    final price = subscription.price;
    return switch (subscription.period) {
      BillingPeriod.weekly => price * 52,
      BillingPeriod.monthly => price * 12,
      BillingPeriod.quarterly => price * 4,
      BillingPeriod.yearly => price,
      BillingPeriod.customDays => price.scaled(
        daysPerYear / _requireCustomDays(subscription.customDays),
      ),
    };
  }

  Money monthlyEquivalent(Subscription subscription) =>
      yearlyCost(subscription).dividedBy(12);

  int daysLeft(Subscription subscription, CalendarDate today) =>
      today.daysUntil(subscription.nextBillingDate);

  double cycleProgress(Subscription subscription, CalendarDate today) {
    final cycleStart = subscription.isTrial
        ? subscription.startDate
        : previousDate(
            subscription.nextBillingDate,
            subscription.period,
            anchorDay: subscription.anchorDay,
            customDays: subscription.customDays,
          );
    final length = cycleStart.daysUntil(subscription.nextBillingDate);
    if (length <= 0) return 0;
    final left = daysLeft(subscription, today);
    return (left / length).clamp(0.0, 1.0);
  }

  int _requireCustomDays(int? customDays) {
    if (customDays == null || customDays < 1) {
      throw ArgumentError.value(customDays, 'customDays', 'must be ≥ 1');
    }
    return customDays;
  }
}
