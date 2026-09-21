import 'package:flutter/foundation.dart';

import 'package:lapse/features/backup/domain/backup_settings.dart';
import 'package:lapse/features/subscriptions/domain/entities/charge.dart';
import 'package:lapse/features/subscriptions/domain/entities/subscription.dart';

@immutable
class BackupData {
  BackupData({
    required this.exportedAt,
    required this.settings,
    required List<Subscription> subscriptions,
    required List<Charge> charges,
  }) : subscriptions = List.unmodifiable(subscriptions),
       charges = List.unmodifiable(charges);

  final DateTime exportedAt;
  final BackupSettings settings;
  final List<Subscription> subscriptions;
  final List<Charge> charges;

  @override
  bool operator ==(Object other) =>
      other is BackupData &&
      other.exportedAt == exportedAt &&
      other.settings == settings &&
      listEquals(other.subscriptions, subscriptions) &&
      listEquals(other.charges, charges);

  @override
  int get hashCode => Object.hash(
    exportedAt,
    settings,
    Object.hashAll(subscriptions),
    Object.hashAll(charges),
  );

  @override
  String toString() =>
      'BackupData(${subscriptions.length} subscriptions, '
      '${charges.length} charges, exported $exportedAt)';
}
