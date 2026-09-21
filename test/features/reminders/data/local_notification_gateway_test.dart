import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lapse/features/reminders/data/local_notification_gateway.dart';
import 'package:lapse/features/reminders/data/notification_action_ids.dart';
import 'package:lapse/features/reminders/data/notification_launch.dart';
import 'package:lapse/features/reminders/data/notification_tap.dart';
import 'package:lapse/features/reminders/data/reminder_permission.dart';
import 'package:lapse/features/reminders/domain/planned_reminder.dart';
import 'package:lapse/features/reminders/domain/reminder_kind.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

const _channel = MethodChannel('dexterous.com/flutter/local_notifications');

typedef _Json = Map<Object?, Object?>;

@pragma('vm:entry-point')
void _backgroundHandler(NotificationResponse response) {}

PlannedReminder _reminder({
  int id = 101,
  bool hasCancelLink = true,
  DateTime? fireAt,
}) => PlannedReminder(
  id: id,
  subscriptionId: 'sub-$id',
  fireAt: fireAt ?? DateTime.now().add(const Duration(days: 3)),
  title: 'Spotify renews in 3 days',
  body: 'Rs 299 on Mon, 21 Sep. Tap to cancel.',
  kind: ReminderKind.renewal,
  hasCancelLink: hasCancelLink,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late List<MethodCall> calls;
  late Map<String, Object? Function(MethodCall call)> answers;
  late LocalNotificationGateway gateway;

  _Json argsOf(String method) =>
      calls.lastWhere((c) => c.method == method).arguments as _Json;

  Future<void> deliver(_Json arguments) async {
    const codec = StandardMethodCodec();
    await messenger.handlePlatformMessage(
      _channel.name,
      codec.encodeMethodCall(
        MethodCall('didReceiveNotificationResponse', arguments),
      ),
      (_) {},
    );
  }

  setUpAll(tzdata.initializeTimeZones);

  setUp(() {
    tz.setLocalLocation(tz.getLocation('Asia/Karachi'));
    FlutterLocalNotificationsPlatform.instance =
        AndroidFlutterLocalNotificationsPlugin();
    calls = [];
    answers = {};
    messenger.setMockMethodCallHandler(_channel, (call) async {
      calls.add(call);
      final answer = answers[call.method];
      return answer?.call(call);
    });
    gateway = LocalNotificationGateway();
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(_channel, null);
  });

  group('initialize', () {
    test(
      'uses the status-bar icon and creates the reminders channel',
      () async {
        answers['initialize'] = (_) => true;

        await gateway.initialize(onTap: (_) {});

        expect(calls.map((c) => c.method), [
          'initialize',
          'createNotificationChannel',
        ]);
        expect(argsOf('initialize')['defaultIcon'], 'ic_stat_lapse');
        expect(argsOf('initialize').containsKey('callback_handle'), isFalse);
        final channel = argsOf('createNotificationChannel');
        expect(channel['id'], 'renewal_reminders');
        expect(channel['name'], 'Renewal reminders');
        expect(
          channel['description'],
          'Heads-up before a subscription or free trial charges you',
        );
        expect(channel['importance'], Importance.high.value);
      },
    );

    test('forwards the background handler to the plugin', () async {
      answers['initialize'] = (_) => true;
      gateway = LocalNotificationGateway(
        onBackgroundResponse: _backgroundHandler,
      );

      await gateway.initialize(onTap: (_) {});

      expect(argsOf('initialize')['callback_handle'], isA<int>());
      expect(argsOf('initialize')['dispatcher_handle'], isA<int>());
    });

    test('parses foreground responses and passes taps on', () async {
      answers['initialize'] = (_) => true;
      final taps = <NotificationTap>[];
      await gateway.initialize(onTap: taps.add);

      await deliver({
        'notificationId': 1,
        'actionId': null,
        'input': null,
        'payload': 'sub-1',
        'notificationResponseType':
            NotificationResponseType.selectedNotification.index,
      });
      await deliver({
        'notificationId': 1,
        'actionId': NotificationActionIds.cancelNow,
        'input': null,
        'payload': 'sub-2',
        'notificationResponseType':
            NotificationResponseType.selectedNotificationAction.index,
      });
      await deliver({
        'notificationId': 1,
        'actionId': null,
        'input': null,
        'payload': null,
        'notificationResponseType':
            NotificationResponseType.selectedNotification.index,
      });

      expect(taps, const [
        NotificationTap(
          subscriptionId: 'sub-1',
          action: NotificationAction.open,
        ),
        NotificationTap(
          subscriptionId: 'sub-2',
          action: NotificationAction.cancelNow,
        ),
      ]);
    });
  });

  group('launchDetails', () {
    _Json launch({required bool launched, String? payload, String? action}) => {
      'notificationLaunchedApp': launched,
      'notificationResponse': {
        'notificationId': 3,
        'actionId': action,
        'input': null,
        'notificationResponseType': action == null
            ? NotificationResponseType.selectedNotification.index
            : NotificationResponseType.selectedNotificationAction.index,
        'payload': payload,
      },
    };

    test('returns the tap that launched the app', () async {
      answers['getNotificationAppLaunchDetails'] = (_) =>
          launch(launched: true, payload: 'sub-3');

      expect(
        await gateway.launchDetails(),
        const NotificationLaunch(
          NotificationTap(
            subscriptionId: 'sub-3',
            action: NotificationAction.open,
          ),
        ),
      );
    });

    test('keeps the action of the launching tap', () async {
      answers['getNotificationAppLaunchDetails'] = (_) => launch(
        launched: true,
        payload: 'sub-3',
        action: NotificationActionIds.cancelNow,
      );

      final details = await gateway.launchDetails();

      expect(details?.tap.action, NotificationAction.cancelNow);
    });

    test('is null when a notification did not launch the app', () async {
      answers['getNotificationAppLaunchDetails'] = (_) =>
          launch(launched: false, payload: 'sub-3');

      expect(await gateway.launchDetails(), isNull);
    });

    test('is null without a payload or without details', () async {
      answers['getNotificationAppLaunchDetails'] = (_) =>
          launch(launched: true);
      expect(await gateway.launchDetails(), isNull);

      answers['getNotificationAppLaunchDetails'] = (_) => {
        'notificationLaunchedApp': true,
      };
      expect(await gateway.launchDetails(), isNull);

      answers.remove('getNotificationAppLaunchDetails');
      expect(await gateway.launchDetails(), isNull);
    });
  });

  group('permissions', () {
    test('maps areNotificationsEnabled', () async {
      answers['areNotificationsEnabled'] = (_) => true;
      expect(await gateway.permission(), ReminderPermission.granted);

      answers['areNotificationsEnabled'] = (_) => false;
      expect(await gateway.permission(), ReminderPermission.denied);

      answers.remove('areNotificationsEnabled');
      expect(await gateway.permission(), ReminderPermission.unknown);
    });

    test('maps requestNotificationsPermission', () async {
      answers['requestNotificationsPermission'] = (_) => true;
      expect(await gateway.requestPermission(), ReminderPermission.granted);

      answers['requestNotificationsPermission'] = (_) => false;
      expect(await gateway.requestPermission(), ReminderPermission.denied);
    });

    test(
      'falls back to the enabled state when the request says nothing',
      () async {
        answers['areNotificationsEnabled'] = (_) => true;

        expect(await gateway.requestPermission(), ReminderPermission.granted);
        expect(calls.map((c) => c.method), [
          'requestNotificationsPermission',
          'areNotificationsEnabled',
        ]);
      },
    );

    test('exact alarms', () async {
      answers['canScheduleExactNotifications'] = (_) => true;
      expect(await gateway.canScheduleExact(), isTrue);

      answers['canScheduleExactNotifications'] = (_) => false;
      expect(await gateway.canScheduleExact(), isFalse);

      answers.remove('canScheduleExactNotifications');
      expect(await gateway.canScheduleExact(), isFalse);

      await gateway.requestExactAlarms();
      expect(calls.last.method, 'requestExactAlarmsPermission');
    });
  });

  group('schedule', () {
    test('maps the reminder onto zonedSchedule', () async {
      final reminder = _reminder();

      await gateway.schedule(reminder, exact: true);

      final args = argsOf('zonedSchedule');
      expect(args['id'], 101);
      expect(args['title'], 'Spotify renews in 3 days');
      expect(args['body'], 'Rs 299 on Mon, 21 Sep. Tap to cancel.');
      expect(args['payload'], 'sub-101');
      expect(args['timeZoneName'], 'Asia/Karachi');
      final scheduledAt = DateTime.parse(
        args['scheduledDateTimeISO8601']! as String,
      );
      expect(
        scheduledAt.millisecondsSinceEpoch ~/ 1000,
        reminder.fireAt.millisecondsSinceEpoch ~/ 1000,
      );
      final specifics = args['platformSpecifics']! as _Json;
      expect(specifics['scheduleMode'], 'exactAllowWhileIdle');
      expect(specifics['channelId'], 'renewal_reminders');
      expect(specifics['icon'], 'ic_stat_lapse');
      final actions = (specifics['actions']! as List<Object?>).cast<_Json>();
      expect(actions.map((a) => a['id']), ['cancel_now', 'snooze_1d']);
    });

    test('keeps the wall-clock time in the local zone', () async {
      final fireAt = DateTime.now().add(const Duration(days: 5));
      final expected = tz.TZDateTime.from(fireAt, tz.local);

      await gateway.schedule(_reminder(fireAt: fireAt), exact: true);

      final wallClock = argsOf('zonedSchedule')['scheduledDateTime']! as String;
      expect(
        wallClock,
        startsWith(
          '${expected.year}-'
          '${expected.month.toString().padLeft(2, '0')}-'
          '${expected.day.toString().padLeft(2, '0')}T'
          '${expected.hour.toString().padLeft(2, '0')}:'
          '${expected.minute.toString().padLeft(2, '0')}',
        ),
      );
    });

    test('uses inexact mode when exact alarms are not allowed', () async {
      await gateway.schedule(_reminder(), exact: false);

      final specifics = argsOf('zonedSchedule')['platformSpecifics']! as _Json;
      expect(specifics['scheduleMode'], 'inexactAllowWhileIdle');
    });

    test('omits the cancel action without a cancel link', () async {
      await gateway.schedule(_reminder(hasCancelLink: false), exact: false);

      final specifics = argsOf('zonedSchedule')['platformSpecifics']! as _Json;
      final actions = (specifics['actions']! as List<Object?>).cast<_Json>();
      expect(actions.map((a) => a['id']), ['snooze_1d']);
    });
  });

  group('show, cancel and pending', () {
    test('showNow shows immediately with the same content', () async {
      await gateway.showNow(_reminder(id: 5));

      final args = argsOf('show');
      expect(args['id'], 5);
      expect(args['title'], 'Spotify renews in 3 days');
      expect(args['payload'], 'sub-5');
      final specifics = args['platformSpecifics']! as _Json;
      expect(specifics['channelId'], 'renewal_reminders');
    });

    test('cancel and cancelAll reach the plugin', () async {
      await gateway.cancel(9);
      await gateway.cancelAll();

      expect(calls.map((c) => c.method), ['cancel', 'cancelAll']);
      expect(argsOf('cancel')['id'], 9);
    });

    test('pendingIds lists the pending request ids', () async {
      answers['pendingNotificationRequests'] = (_) => [
        {'id': 3, 'title': 'a', 'body': 'b', 'payload': 'x'},
        {'id': 8, 'title': 'c', 'body': 'd', 'payload': 'y'},
      ];

      expect(await gateway.pendingIds(), [3, 8]);
    });

    test('pendingIds is empty when nothing is pending', () async {
      expect(await gateway.pendingIds(), isEmpty);
    });
  });
}
