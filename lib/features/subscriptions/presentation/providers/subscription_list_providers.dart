import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:lapse/features/subscriptions/domain/entities/charge.dart';
import 'package:lapse/features/subscriptions/domain/entities/subscription.dart';
import 'package:lapse/features/subscriptions/presentation/providers/subscription_service_providers.dart';

final subscriptionsProvider = StreamProvider<List<Subscription>>(
  (ref) => ref.watch(subscriptionRepositoryProvider).watchAll(),
);

final activeSubscriptionsProvider = Provider<AsyncValue<List<Subscription>>>(
  (ref) => ref
      .watch(subscriptionsProvider)
      .whenData((all) => all.where((s) => s.isActive && !s.isTrial).toList()),
);

final trialSubscriptionsProvider = Provider<AsyncValue<List<Subscription>>>(
  (ref) => ref
      .watch(subscriptionsProvider)
      .whenData((all) => all.where((s) => s.isActive && s.isTrial).toList()),
);

final cancelledSubscriptionsProvider = Provider<AsyncValue<List<Subscription>>>(
  (ref) => ref.watch(subscriptionsProvider).whenData((all) {
    final cancelled = all.where((s) => s.isCancelled).toList()
      ..sort(
        (a, b) => (b.cancelledAt ?? b.updatedAt).compareTo(
          a.cancelledAt ?? a.updatedAt,
        ),
      );
    return cancelled;
  }),
);

final StreamProviderFamily<Subscription?, String> subscriptionByIdProvider =
    StreamProvider.autoDispose.family<Subscription?, String>(
      (ref, id) => ref.watch(subscriptionRepositoryProvider).watchById(id),
    );

final FutureProviderFamily<List<Charge>, String> chargesProvider =
    FutureProvider.autoDispose.family<List<Charge>, String>(
      (ref, subscriptionId) {
        ref.watch(subscriptionsProvider);
        return ref
            .watch(subscriptionRepositoryProvider)
            .chargesFor(subscriptionId);
      },
    );
