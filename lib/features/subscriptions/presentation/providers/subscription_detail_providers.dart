import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:lapse/core/domain/money.dart';
import 'package:lapse/core/domain/urgency.dart';
import 'package:lapse/core/providers/clock_providers.dart';
import 'package:lapse/features/subscriptions/domain/entities/charge.dart';
import 'package:lapse/features/subscriptions/domain/entities/subscription.dart';
import 'package:lapse/features/subscriptions/presentation/providers/subscription_detail.dart';
import 'package:lapse/features/subscriptions/presentation/providers/subscription_list_providers.dart';
import 'package:lapse/features/subscriptions/presentation/providers/subscription_service_providers.dart';

final ProviderFamily<AsyncValue<SubscriptionDetail?>, String>
subscriptionDetailProvider = Provider.autoDispose
    .family<AsyncValue<SubscriptionDetail?>, String>((ref, id) {
      final subscriptionValue = ref.watch(subscriptionByIdProvider(id));
      final chargesValue = ref.watch(chargesProvider(id));
      final today = ref.watch(todayProvider);
      final engine = ref.watch(billingEngineProvider);

      if (subscriptionValue.hasError) {
        return AsyncError(
          subscriptionValue.error!,
          subscriptionValue.stackTrace!,
        );
      }
      if (!subscriptionValue.hasValue) return const AsyncLoading();
      final subscription = subscriptionValue.value;
      if (subscription == null) return const AsyncData(null);
      if (chargesValue.hasError) {
        return AsyncError(chargesValue.error!, chargesValue.stackTrace!);
      }
      final charges = chargesValue.value;
      if (charges == null) return const AsyncLoading();

      final daysLeft = engine.daysLeft(subscription, today);
      return AsyncData(
        SubscriptionDetail(
          subscription: subscription,
          totalPaid: _totalPaid(subscription, charges),
          chargeCount: charges.length,
          daysLeft: daysLeft,
          urgency: Urgency.fromDaysLeft(daysLeft),
          progress: engine.cycleProgress(subscription, today),
          ringState: _ringState(subscription, daysLeft),
        ),
      );
    });

Money _totalPaid(Subscription subscription, List<Charge> charges) {
  final currency = subscription.price.currency;
  return charges
      .where((c) => c.amount.currency == currency)
      .fold(Money.zero(currency), (sum, c) => sum + c.amount);
}

DetailRingState _ringState(Subscription subscription, int daysLeft) {
  if (subscription.isCancelled) return DetailRingState.cancelled;
  if (daysLeft == 0) return DetailRingState.today;
  if (daysLeft < 0) return DetailRingState.overdue;
  return DetailRingState.upcoming;
}
