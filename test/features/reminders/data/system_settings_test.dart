import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lapse/features/reminders/data/system_settings.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() {
    messenger.setMockMethodCallHandler(systemSettingsChannel, null);
  });

  test('invokes openNotificationSettings on lapse/system', () async {
    final calls = <MethodCall>[];
    messenger.setMockMethodCallHandler(systemSettingsChannel, (call) async {
      calls.add(call);
      return null;
    });

    await openNotificationSettings();

    expect(systemSettingsChannel.name, 'lapse/system');
    expect(calls.map((c) => c.method), ['openNotificationSettings']);
  });

  test('does not throw when the channel is missing', () async {
    await expectLater(openNotificationSettings(), completes);
  });
}
