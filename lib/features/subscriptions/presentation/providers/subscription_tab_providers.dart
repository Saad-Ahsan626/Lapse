import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:lapse/features/subscriptions/domain/entities/subscription.dart';
import 'package:lapse/features/subscriptions/domain/services/billing_engine.dart';
import 'package:lapse/features/subscriptions/presentation/providers/subscription_list_providers.dart';
import 'package:lapse/features/subscriptions/presentation/providers/subscription_service_providers.dart';
import 'package:lapse/features/subscriptions/presentation/providers/subscription_sort.dart';
import 'package:lapse/features/subscriptions/presentation/providers/subscription_tab.dart';
import 'package:lapse/features/subscriptions/presentation/providers/tab_counts.dart';

final subscriptionSortProvider =
    NotifierProvider<SubscriptionSortController, SubscriptionSort>(
      SubscriptionSortController.new,
    );

class SubscriptionSortController extends Notifier<SubscriptionSort> {
  @override
  SubscriptionSort build() => SubscriptionSort.nextCharge;

  void select(SubscriptionSort sort) {
    if (sort == state) return;
    state = sort;
  }
}

final subscriptionTabCountsProvider = Provider<AsyncValue<TabCounts>>(
  (ref) => ref.watch(subscriptionsProvider).whenData((all) {
    var active = 0;
    var trials = 0;
    var cancelled = 0;
    for (final subscription in all) {
      if (subscription.isCancelled) {
        cancelled++;
      } else if (subscription.isTrial) {
        trials++;
      } else {
        active++;
      }
    }
    return TabCounts(active: active, trials: trials, cancelled: cancelled);
  }),
);

final ProviderFamily<AsyncValue<List<Subscription>>, SubscriptionTab>
subscriptionTabProvider =
    Provider.family<AsyncValue<List<Subscription>>, SubscriptionTab>((
      ref,
      tab,
    ) {
      final sort = ref.watch(subscriptionSortProvider);
      final engine = ref.watch(billingEngineProvider);
      return ref.watch(subscriptionsProvider).whenData((all) {
        final items = all.where((s) => _belongsTo(s, tab)).toList()
          ..sort(_comparator(sort, tab, engine));
        return List<Subscription>.unmodifiable(items);
      });
    });

bool _belongsTo(Subscription s, SubscriptionTab tab) => switch (tab) {
  SubscriptionTab.active => s.isActive && !s.isTrial,
  SubscriptionTab.trials => s.isActive && s.isTrial,
  SubscriptionTab.cancelled => s.isCancelled,
};

Comparator<Subscription> _comparator(
  SubscriptionSort sort,
  SubscriptionTab tab,
  BillingEngine engine,
) => switch (sort) {
  SubscriptionSort.nextCharge when tab == SubscriptionTab.cancelled =>
    (a, b) => _thenName(_cancelledAt(b).compareTo(_cancelledAt(a)), a, b),
  SubscriptionSort.nextCharge => (a, b) => _thenName(
    a.nextBillingDate.compareTo(b.nextBillingDate),
    a,
    b,
  ),
  SubscriptionSort.price => (a, b) => _thenName(
    engine.yearlyCost(b).minor.compareTo(engine.yearlyCost(a).minor),
    a,
    b,
  ),
  SubscriptionSort.name => (a, b) => _thenName(0, a, b),
};

DateTime _cancelledAt(Subscription s) => s.cancelledAt ?? s.updatedAt;

int _thenName(int primary, Subscription a, Subscription b) {
  if (primary != 0) return primary;
  final byName = a.name.toLowerCase().compareTo(b.name.toLowerCase());
  if (byName != 0) return byName;
  return a.id.compareTo(b.id);
}
