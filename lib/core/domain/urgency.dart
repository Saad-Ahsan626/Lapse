enum Urgency {
  urgent,

  warning,

  normal
  ;

  factory Urgency.fromDaysLeft(int daysLeft) {
    if (daysLeft <= 1) return Urgency.urgent;
    if (daysLeft <= 3) return Urgency.warning;
    return Urgency.normal;
  }
}
