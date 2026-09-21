import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:lapse/features/reminders/data/notification_action.dart';
import 'package:lapse/features/reminders/data/notification_action_ids.dart';

export 'package:lapse/features/reminders/data/notification_action.dart';

@immutable
class NotificationTap {
  const NotificationTap({required this.subscriptionId, required this.action});

  final String subscriptionId;
  final NotificationAction action;

  static NotificationTap? fromResponse(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) {
      return null;
    }
    return NotificationTap(
      subscriptionId: payload,
      action: switch (response.actionId) {
        NotificationActionIds.cancelNow => NotificationAction.cancelNow,
        NotificationActionIds.snooze => NotificationAction.snooze,
        _ => NotificationAction.open,
      },
    );
  }

  @override
  bool operator ==(Object other) =>
      other is NotificationTap &&
      other.subscriptionId == subscriptionId &&
      other.action == action;

  @override
  int get hashCode => Object.hash(subscriptionId, action);

  @override
  String toString() => 'NotificationTap($subscriptionId, ${action.name})';
}
