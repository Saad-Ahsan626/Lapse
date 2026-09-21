import 'package:flutter/foundation.dart';
import 'package:lapse/features/subscriptions/presentation/providers/subscription_tab.dart';

@immutable
class TabCounts {
  const TabCounts({
    required this.active,
    required this.trials,
    required this.cancelled,
  });

  static const empty = TabCounts(active: 0, trials: 0, cancelled: 0);

  final int active;
  final int trials;
  final int cancelled;

  int get total => active + trials + cancelled;

  int of(SubscriptionTab tab) => switch (tab) {
    SubscriptionTab.active => active,
    SubscriptionTab.trials => trials,
    SubscriptionTab.cancelled => cancelled,
  };

  @override
  bool operator ==(Object other) =>
      other is TabCounts &&
      other.active == active &&
      other.trials == trials &&
      other.cancelled == cancelled;

  @override
  int get hashCode => Object.hash(active, trials, cancelled);

  @override
  String toString() => 'TabCounts($active, $trials, $cancelled)';
}
