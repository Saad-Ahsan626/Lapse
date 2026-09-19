import 'package:flutter/foundation.dart';

import 'package:lapse/core/domain/calendar_date.dart';
import 'package:lapse/core/domain/money.dart';

@immutable
class Charge {
  const Charge({
    required this.id,
    required this.subscriptionId,
    required this.amount,
    required this.chargedOn,
  });

  final String id;
  final String subscriptionId;
  final Money amount;
  final CalendarDate chargedOn;

  @override
  bool operator ==(Object other) =>
      other is Charge &&
      other.id == id &&
      other.subscriptionId == subscriptionId &&
      other.amount == amount &&
      other.chargedOn == chargedOn;

  @override
  int get hashCode => Object.hash(id, subscriptionId, amount, chargedOn);

  @override
  String toString() => 'Charge($subscriptionId, $amount on $chargedOn)';
}
