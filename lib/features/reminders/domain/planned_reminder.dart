import 'package:flutter/foundation.dart';

import 'package:lapse/features/reminders/domain/reminder_kind.dart';

@immutable
class PlannedReminder {
  const PlannedReminder({
    required this.id,
    required this.subscriptionId,
    required this.fireAt,
    required this.title,
    required this.body,
    required this.kind,
    required this.hasCancelLink,
  });

  final int id;
  final String subscriptionId;
  final DateTime fireAt;
  final String title;
  final String body;
  final ReminderKind kind;
  final bool hasCancelLink;

  @override
  bool operator ==(Object other) =>
      other is PlannedReminder &&
      other.id == id &&
      other.subscriptionId == subscriptionId &&
      other.fireAt == fireAt &&
      other.title == title &&
      other.body == body &&
      other.kind == kind &&
      other.hasCancelLink == hasCancelLink;

  @override
  int get hashCode => Object.hash(
    id,
    subscriptionId,
    fireAt,
    title,
    body,
    kind,
    hasCancelLink,
  );

  @override
  String toString() =>
      'PlannedReminder($id, $subscriptionId, $fireAt, ${kind.name}, '
      '"$title", "$body"${hasCancelLink ? ', cancel link' : ''})';
}
