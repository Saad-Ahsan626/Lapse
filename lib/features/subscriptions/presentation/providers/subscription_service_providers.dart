import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lapse/core/providers/clock_providers.dart';
import 'package:lapse/core/providers/storage_providers.dart';
import 'package:lapse/features/subscriptions/data/repositories/subscription_repository_impl.dart';
import 'package:lapse/features/subscriptions/domain/repositories/subscription_repository.dart';
import 'package:lapse/features/subscriptions/domain/services/billing_engine.dart';
import 'package:lapse/features/subscriptions/domain/usecases/delete_subscription.dart';
import 'package:lapse/features/subscriptions/domain/usecases/mark_cancelled.dart';
import 'package:lapse/features/subscriptions/domain/usecases/restore_subscription.dart';
import 'package:lapse/features/subscriptions/domain/usecases/roll_over_due_subscriptions.dart';
import 'package:lapse/features/subscriptions/domain/usecases/save_subscription.dart';
import 'package:lapse/features/subscriptions/domain/validation/subscription_validator.dart';

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>((ref) {
  final repository = SubscriptionRepositoryImpl(ref.watch(databaseProvider));
  ref.onDispose(repository.dispose);
  return repository;
});

final billingEngineProvider = Provider<BillingEngine>(
  (ref) => const BillingEngine(),
);

final subscriptionValidatorProvider = Provider<SubscriptionValidator>(
  (ref) => const SubscriptionValidator(),
);

final saveSubscriptionProvider = Provider<SaveSubscription>(
  (ref) => SaveSubscription(
    repository: ref.watch(subscriptionRepositoryProvider),
    validator: ref.watch(subscriptionValidatorProvider),
    clock: ref.watch(clockProvider),
    newId: ref.watch(newIdProvider),
  ),
);

final deleteSubscriptionProvider = Provider<DeleteSubscription>(
  (ref) => DeleteSubscription(
    repository: ref.watch(subscriptionRepositoryProvider),
  ),
);

final markCancelledProvider = Provider<MarkCancelled>(
  (ref) => MarkCancelled(
    repository: ref.watch(subscriptionRepositoryProvider),
    engine: ref.watch(billingEngineProvider),
    clock: ref.watch(clockProvider),
  ),
);

final restoreSubscriptionProvider = Provider<RestoreSubscription>(
  (ref) => RestoreSubscription(
    repository: ref.watch(subscriptionRepositoryProvider),
    engine: ref.watch(billingEngineProvider),
    clock: ref.watch(clockProvider),
  ),
);

final rollOverDueSubscriptionsProvider = Provider<RollOverDueSubscriptions>(
  (ref) => RollOverDueSubscriptions(
    repository: ref.watch(subscriptionRepositoryProvider),
    engine: ref.watch(billingEngineProvider),
    clock: ref.watch(clockProvider),
    newId: ref.watch(newIdProvider),
  ),
);
