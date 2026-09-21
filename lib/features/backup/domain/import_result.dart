import 'package:flutter/foundation.dart';

import 'package:lapse/features/backup/domain/import_mode.dart';

@immutable
class ImportResult {
  const ImportResult({
    required this.mode,
    required this.subscriptions,
    required this.payments,
  });

  final ImportMode mode;
  final int subscriptions;
  final int payments;

  @override
  bool operator ==(Object other) =>
      other is ImportResult &&
      other.mode == mode &&
      other.subscriptions == subscriptions &&
      other.payments == payments;

  @override
  int get hashCode => Object.hash(mode, subscriptions, payments);

  @override
  String toString() =>
      'ImportResult(${mode.name}, $subscriptions subscriptions, '
      '$payments payments)';
}
