import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lapse/features/reminders/data/local_timezone.dart';
import 'package:timezone/timezone.dart' as tz;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('flutter_timezone');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  void respond(Object? Function() answer) {
    messenger.setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'getLocalTimezone');
      return answer();
    });
  }

  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
  });

  test('sets tz.local to the device zone and returns its name', () async {
    respond(() => 'Asia/Karachi');

    final name = await configureLocalTimezone();

    expect(name, 'Asia/Karachi');
    expect(tz.local.name, 'Asia/Karachi');
  });

  test('accepts the map form of the platform answer', () async {
    respond(() => {'identifier': 'Europe/London'});

    expect(await configureLocalTimezone(), 'Europe/London');
    expect(tz.local.name, 'Europe/London');
  });

  test('can switch zones on a later call', () async {
    respond(() => 'Asia/Karachi');
    await configureLocalTimezone();
    respond(() => 'America/New_York');

    expect(await configureLocalTimezone(), 'America/New_York');
    expect(tz.local.name, 'America/New_York');
  });

  test('the bundled data resolves the zones the app relies on', () async {
    for (final zone in const [
      'Asia/Karachi',
      'America/New_York',
      'Europe/London',
      'Asia/Kolkata',
      'Australia/Sydney',
    ]) {
      respond(() => zone);
      expect(await configureLocalTimezone(), zone);
      expect(tz.local.name, zone);
    }
  });

  test('falls back to UTC when the platform call fails', () async {
    respond(() => throw PlatformException(code: 'boom'));

    expect(await configureLocalTimezone(), 'UTC');
    expect(tz.local, tz.UTC);
  });

  test('falls back to UTC for an unknown zone', () async {
    respond(() => 'Mars/Olympus_Mons');

    expect(await configureLocalTimezone(), 'UTC');
    expect(tz.local, tz.UTC);
  });

  test('falls back to UTC when the platform returns nothing', () async {
    respond(() => null);

    expect(await configureLocalTimezone(), 'UTC');
    expect(tz.local, tz.UTC);
  });

  test('falls back to UTC when the plugin is missing', () async {
    expect(await configureLocalTimezone(), 'UTC');
    expect(tz.local, tz.UTC);
  });
}
