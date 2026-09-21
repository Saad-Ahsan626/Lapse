import 'package:flutter/foundation.dart';
import 'package:lapse/features/reminders/data/notification_tap.dart';

@immutable
class NotificationLaunch {
  const NotificationLaunch(this.tap);

  final NotificationTap tap;

  @override
  bool operator ==(Object other) =>
      other is NotificationLaunch && other.tap == tap;

  @override
  int get hashCode => tap.hashCode;

  @override
  String toString() => 'NotificationLaunch($tap)';
}
