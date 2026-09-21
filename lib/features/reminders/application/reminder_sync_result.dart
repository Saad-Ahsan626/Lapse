import 'package:flutter/foundation.dart';

@immutable
class ReminderSyncResult {
  const ReminderSyncResult({
    required this.scheduled,
    required this.exact,
    required this.syncedAt,
  });

  final int scheduled;
  final bool exact;
  final DateTime syncedAt;

  @override
  bool operator ==(Object other) =>
      other is ReminderSyncResult &&
      other.scheduled == scheduled &&
      other.exact == exact &&
      other.syncedAt == syncedAt;

  @override
  int get hashCode => Object.hash(scheduled, exact, syncedAt);

  @override
  String toString() =>
      'ReminderSyncResult($scheduled, ${exact ? 'exact' : 'inexact'}, '
      '$syncedAt)';
}
