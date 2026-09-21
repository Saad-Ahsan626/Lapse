import 'package:flutter/foundation.dart';
import 'package:lapse/core/domain/money.dart';
import 'package:lapse/core/domain/urgency.dart';
import 'package:lapse/features/subscriptions/domain/entities/subscription.dart';

enum DetailRingState { upcoming, today, overdue, cancelled }

@immutable
class SubscriptionDetail {
  const SubscriptionDetail({
    required this.subscription,
    required this.totalPaid,
    required this.chargeCount,
    required this.daysLeft,
    required this.urgency,
    required this.progress,
    required this.ringState,
  });

  final Subscription subscription;
  final Money totalPaid;
  final int chargeCount;
  final int daysLeft;
  final Urgency urgency;
  final double progress;
  final DetailRingState ringState;

  @override
  bool operator ==(Object other) =>
      other is SubscriptionDetail &&
      other.subscription == subscription &&
      other.totalPaid == totalPaid &&
      other.chargeCount == chargeCount &&
      other.daysLeft == daysLeft &&
      other.urgency == urgency &&
      other.progress == progress &&
      other.ringState == ringState;

  @override
  int get hashCode => Object.hash(
    subscription,
    totalPaid,
    chargeCount,
    daysLeft,
    urgency,
    progress,
    ringState,
  );

  @override
  String toString() =>
      'SubscriptionDetail(${subscription.name}, ${ringState.name}, '
      '$daysLeft days, paid $totalPaid over $chargeCount)';
}
