enum BillingPeriod {
  weekly,
  monthly,
  quarterly,
  yearly,
  customDays
  ;

  static BillingPeriod? fromStorage(String value) => values.asNameMap()[value];
}
