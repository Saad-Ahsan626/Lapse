import 'package:lapse/core/platform/app_version.dart';
import 'package:lapse/core/platform/system_bridge.dart';

class FakeSystemBridge implements SystemBridge {
  FakeSystemBridge({
    this.ignoringBatteryOptimizations = true,
    this.version = const AppVersion(name: '0.1.0', build: '1'),
    this.documentToOpen,
    this.saveSucceeds = true,
  });

  bool ignoringBatteryOptimizations;
  AppVersion version;
  List<int>? documentToOpen;
  bool saveSucceeds;

  int notificationSettingsOpened = 0;
  int batterySettingsOpened = 0;
  int documentsRequested = 0;
  final List<({String fileName, String mimeType, List<int> bytes})> saved = [];

  @override
  Future<void> openNotificationSettings() async {
    notificationSettingsOpened++;
  }

  @override
  Future<AppVersion> appVersion() async => version;

  @override
  Future<bool> isIgnoringBatteryOptimizations() async =>
      ignoringBatteryOptimizations;

  @override
  Future<void> openBatterySettings() async {
    batterySettingsOpened++;
  }

  @override
  Future<bool> saveDocument({
    required String fileName,
    required String mimeType,
    required List<int> bytes,
  }) async {
    if (!saveSucceeds) return false;
    saved.add((
      fileName: fileName,
      mimeType: mimeType,
      bytes: List<int>.unmodifiable(bytes),
    ));
    return true;
  }

  @override
  Future<List<int>?> openDocument({required String mimeType}) async {
    documentsRequested++;
    return documentToOpen;
  }
}
