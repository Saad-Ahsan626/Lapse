import 'package:flutter_test/flutter_test.dart';
import 'package:lapse/core/platform/app_version.dart';

import 'fake_system_bridge.dart';

void main() {
  test('defaults to a healthy device', () async {
    final bridge = FakeSystemBridge();
    expect(await bridge.isIgnoringBatteryOptimizations(), isTrue);
    expect(
      await bridge.appVersion(),
      const AppVersion(name: '0.1.0', build: '1'),
    );
    expect(await bridge.openDocument(mimeType: 'application/json'), isNull);
  });

  test('records settings opens and saved documents', () async {
    final bridge = FakeSystemBridge();
    await bridge.openNotificationSettings();
    await bridge.openBatterySettings();
    await bridge.openBatterySettings();
    final ok = await bridge.saveDocument(
      fileName: 'a.json',
      mimeType: 'application/json',
      bytes: const [1, 2],
    );
    expect(ok, isTrue);
    expect(bridge.notificationSettingsOpened, 1);
    expect(bridge.batterySettingsOpened, 2);
    expect(bridge.saved.single.fileName, 'a.json');
    expect(bridge.saved.single.mimeType, 'application/json');
    expect(bridge.saved.single.bytes, [1, 2]);
  });

  test('cancel paths', () async {
    final bridge = FakeSystemBridge(saveSucceeds: false)
      ..ignoringBatteryOptimizations = false;
    expect(
      await bridge.saveDocument(
        fileName: 'a.json',
        mimeType: 'application/json',
        bytes: const [1],
      ),
      isFalse,
    );
    expect(bridge.saved, isEmpty);
    expect(await bridge.isIgnoringBatteryOptimizations(), isFalse);
  });

  test('returns the document to open', () async {
    final bridge = FakeSystemBridge(documentToOpen: [7, 8]);
    expect(await bridge.openDocument(mimeType: 'application/json'), [7, 8]);
    expect(bridge.documentsRequested, 1);
  });
}
