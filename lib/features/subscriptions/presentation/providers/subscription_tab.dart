enum SubscriptionTab {
  active,
  trials,
  cancelled
  ;

  static SubscriptionTab fromQuery(String? value) => switch (value) {
    'trials' => SubscriptionTab.trials,
    'cancelled' => SubscriptionTab.cancelled,
    _ => SubscriptionTab.active,
  };
}
