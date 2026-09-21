import 'package:flutter/foundation.dart';
import 'package:lapse/features/subscriptions/domain/entities/subscription.dart';

@immutable
class UpcomingCharges {
  const UpcomingCharges({required this.items, required this.isThisMonth});

  final List<Subscription> items;
  final bool isThisMonth;

  bool get isEmpty => items.isEmpty;

  @override
  bool operator ==(Object other) =>
      other is UpcomingCharges &&
      other.isThisMonth == isThisMonth &&
      listEquals(other.items, items);

  @override
  int get hashCode => Object.hash(isThisMonth, Object.hashAll(items));

  @override
  String toString() =>
      'UpcomingCharges(${items.length}, '
      '${isThisMonth ? 'this month' : 'coming up'})';
}
