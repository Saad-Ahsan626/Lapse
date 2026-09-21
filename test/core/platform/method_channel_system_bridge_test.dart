import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lapse/core/platform/app_version.dart';
import 'package:lapse/core/platform/method_channel_system_bridge.dart';
import 'package:lapse/core/platform/system_bridge_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const bridge = MethodChannelSystemBridge();
  final calls = <MethodCall>[];

  void answer(Object? Function(MethodCall call) reply) {
    messenger.setMockMethodCallHandler(systemChannel, (call) async {
      calls.add(call);
      return reply(call);
    });
  }

  setUp(calls.clear);

  tearDown(() {
    messenger.setMockMethodCallHandler(systemChannel, null);
  });

  test('uses the lapse/system channel', () {
    expect(systemChannel.name, 'lapse/system');
  });

  test('provider exposes the method channel bridge', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(
      container.read(systemBridgeProvider),
      isA<MethodChannelSystemBridge>(),
    );
  });

  group('with the platform side answering', () {
    test('openNotificationSettings calls the method', () async {
      answer((_) => null);
      await bridge.openNotificationSettings();
      expect(calls.single.method, 'openNotificationSettings');
      expect(calls.single.arguments, isNull);
    });

    test('appVersion reads name and build', () async {
      answer((_) => {'name': '0.1.0', 'build': '1'});
      final version = await bridge.appVersion();
      expect(calls.single.method, 'appVersion');
      expect(version, const AppVersion(name: '0.1.0', build: '1'));
      expect(version.label, '0.1.0 (1)');
    });

    test('appVersion accepts a numeric build', () async {
      answer((_) => {'name': '2.0.0', 'build': 7});
      expect(
        await bridge.appVersion(),
        const AppVersion(name: '2.0.0', build: '7'),
      );
    });

    test('appVersion falls back when the map is null', () async {
      answer((_) => null);
      expect(
        await bridge.appVersion(),
        MethodChannelSystemBridge.fallbackVersion,
      );
    });

    test('isIgnoringBatteryOptimizations returns the answer', () async {
      answer((_) => false);
      expect(await bridge.isIgnoringBatteryOptimizations(), isFalse);
      expect(calls.single.method, 'isIgnoringBatteryOptimizations');
    });

    test('openBatterySettings calls the method', () async {
      answer((_) => null);
      await bridge.openBatterySettings();
      expect(calls.single.method, 'openBatterySettings');
    });

    test('saveDocument sends name, mime and bytes as Uint8List', () async {
      answer((_) => true);
      final saved = await bridge.saveDocument(
        fileName: 'lapse-backup-2026-09-21.json',
        mimeType: 'application/json',
        bytes: const [123, 125],
      );
      expect(saved, isTrue);
      final call = calls.single;
      expect(call.method, 'saveDocument');
      final args = call.arguments as Map<Object?, Object?>;
      expect(args.keys, unorderedEquals(['fileName', 'mimeType', 'bytes']));
      expect(args['fileName'], 'lapse-backup-2026-09-21.json');
      expect(args['mimeType'], 'application/json');
      expect(args['bytes'], isA<Uint8List>());
      expect(args['bytes'], [123, 125]);
    });

    test('saveDocument returns false when the user cancels', () async {
      answer((_) => false);
      expect(
        await bridge.saveDocument(
          fileName: 'a.json',
          mimeType: 'application/json',
          bytes: Uint8List.fromList([1]),
        ),
        isFalse,
      );
    });

    test('openDocument sends the mime type and returns bytes', () async {
      answer((_) => Uint8List.fromList([1, 2, 3]));
      final bytes = await bridge.openDocument(mimeType: 'application/json');
      expect(calls.single.method, 'openDocument');
      expect(calls.single.arguments, {'mimeType': 'application/json'});
      expect(bytes, [1, 2, 3]);
    });

    test('openDocument returns null when the user cancels', () async {
      answer((_) => null);
      expect(await bridge.openDocument(mimeType: 'application/json'), isNull);
    });

    test('platform errors such as busy reach the caller', () async {
      answer((_) => throw PlatformException(code: 'busy'));
      await expectLater(
        bridge.openDocument(mimeType: 'application/json'),
        throwsA(
          isA<PlatformException>().having((e) => e.code, 'code', 'busy'),
        ),
      );
    });
  });

  group('without the platform side', () {
    test('openNotificationSettings completes', () async {
      await expectLater(bridge.openNotificationSettings(), completes);
    });

    test('appVersion falls back to 0.0.0 (0)', () async {
      expect(
        await bridge.appVersion(),
        const AppVersion(name: '0.0.0', build: '0'),
      );
    });

    test('battery counts as not optimised', () async {
      expect(await bridge.isIgnoringBatteryOptimizations(), isTrue);
    });

    test('openBatterySettings completes', () async {
      await expectLater(bridge.openBatterySettings(), completes);
    });

    test('saveDocument returns false', () async {
      expect(
        await bridge.saveDocument(
          fileName: 'a.json',
          mimeType: 'application/json',
          bytes: const [1],
        ),
        isFalse,
      );
    });

    test('openDocument returns null', () async {
      expect(await bridge.openDocument(mimeType: 'application/json'), isNull);
    });
  });
}
