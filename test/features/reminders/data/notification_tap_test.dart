import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lapse/features/reminders/data/notification_action_ids.dart';
import 'package:lapse/features/reminders/data/notification_launch.dart';
import 'package:lapse/features/reminders/data/notification_tap.dart';

NotificationResponse _response({String? payload, String? actionId}) =>
    NotificationResponse(
      notificationResponseType: actionId == null
          ? NotificationResponseType.selectedNotification
          : NotificationResponseType.selectedNotificationAction,
      id: 7,
      actionId: actionId,
      payload: payload,
    );

void main() {
  group('NotificationTap.fromResponse', () {
    test('body tap without action opens the subscription', () {
      expect(
        NotificationTap.fromResponse(_response(payload: 'sub-1')),
        const NotificationTap(
          subscriptionId: 'sub-1',
          action: NotificationAction.open,
        ),
      );
    });

    test('cancel_now maps to cancelNow', () {
      final tap = NotificationTap.fromResponse(
        _response(payload: 'sub-2', actionId: NotificationActionIds.cancelNow),
      );
      expect(tap?.subscriptionId, 'sub-2');
      expect(tap?.action, NotificationAction.cancelNow);
    });

    test('snooze_1d maps to snooze', () {
      final tap = NotificationTap.fromResponse(
        _response(payload: 'sub-3', actionId: NotificationActionIds.snooze),
      );
      expect(tap?.subscriptionId, 'sub-3');
      expect(tap?.action, NotificationAction.snooze);
    });

    test('action ids match the platform contract', () {
      expect(NotificationActionIds.cancelNow, 'cancel_now');
      expect(NotificationActionIds.snooze, 'snooze_1d');
    });

    test('an unknown action id falls back to open', () {
      final tap = NotificationTap.fromResponse(
        _response(payload: 'sub-4', actionId: 'something_else'),
      );
      expect(tap?.action, NotificationAction.open);
    });

    test('an empty action id falls back to open', () {
      final tap = NotificationTap.fromResponse(
        _response(payload: 'sub-4', actionId: ''),
      );
      expect(tap?.action, NotificationAction.open);
    });

    test('null payload gives no tap', () {
      expect(NotificationTap.fromResponse(_response()), isNull);
      expect(
        NotificationTap.fromResponse(
          _response(actionId: NotificationActionIds.snooze),
        ),
        isNull,
      );
    });

    test('empty payload gives no tap', () {
      expect(NotificationTap.fromResponse(_response(payload: '')), isNull);
    });
  });

  group('value semantics', () {
    test('taps compare by value', () {
      const a = NotificationTap(
        subscriptionId: 'x',
        action: NotificationAction.snooze,
      );
      const b = NotificationTap(
        subscriptionId: 'x',
        action: NotificationAction.snooze,
      );
      const c = NotificationTap(
        subscriptionId: 'x',
        action: NotificationAction.open,
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(c));
      expect(a.toString(), contains('snooze'));
    });

    test('NotificationLaunch wraps a tap and compares by value', () {
      const tap = NotificationTap(
        subscriptionId: 'sub-9',
        action: NotificationAction.cancelNow,
      );
      const launch = NotificationLaunch(tap);
      expect(launch.tap, same(tap));
      expect(launch, const NotificationLaunch(tap));
      expect(launch.hashCode, const NotificationLaunch(tap).hashCode);
      expect(
        launch,
        isNot(
          const NotificationLaunch(
            NotificationTap(
              subscriptionId: 'sub-9',
              action: NotificationAction.open,
            ),
          ),
        ),
      );
      expect(launch.toString(), contains('sub-9'));
    });
  });
}
