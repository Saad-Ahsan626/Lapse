import 'package:flutter/foundation.dart';
import 'package:lapse/features/subscriptions/domain/entities/subscription.dart';

@immutable
class TrialsEnding {
  const TrialsEnding(this.items);

  static const empty = TrialsEnding([]);

  final List<Subscription> items;

  bool get isEmpty => items.isEmpty;

  bool get isNotEmpty => items.isNotEmpty;

  @override
  bool operator ==(Object other) =>
      other is TrialsEnding && listEquals(other.items, items);

  @override
  int get hashCode => Object.hashAll(items);

  @override
  String toString() => 'TrialsEnding(${items.length})';
}
