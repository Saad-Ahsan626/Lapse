import 'package:flutter/foundation.dart';

import 'package:lapse/features/subscriptions/domain/entities/charge.dart';
import 'package:lapse/features/subscriptions/domain/entities/subscription.dart';

@immutable
class RollOverResult {
  RollOverResult({required this.subscription, List<Charge> charges = const []})
    : charges = List.unmodifiable(charges);

  final Subscription subscription;
  final List<Charge> charges;

  bool get changed => charges.isNotEmpty;
}
