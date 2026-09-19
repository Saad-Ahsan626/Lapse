enum SubscriptionStatus {
  active,
  cancelled
  ;

  static SubscriptionStatus? fromStorage(String value) =>
      values.asNameMap()[value];
}
