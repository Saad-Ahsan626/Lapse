enum SubscriptionSort {
  nextCharge('Next charge'),
  price('Price'),
  name('Name')
  ;

  const SubscriptionSort(this.label);

  final String label;
}
