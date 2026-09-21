import 'package:flutter/foundation.dart';

@immutable
class SegmentedTab<T> {
  const SegmentedTab({required this.value, required this.label, this.count});

  final T value;
  final String label;
  final int? count;

  String get semanticLabel => count == null ? label : '$label, $count';
}
