import 'package:lapse/core/platform/app_version.dart';

abstract interface class SystemBridge {
  Future<void> openNotificationSettings();

  Future<AppVersion> appVersion();

  Future<bool> isIgnoringBatteryOptimizations();

  Future<void> openBatterySettings();

  Future<bool> saveDocument({
    required String fileName,
    required String mimeType,
    required List<int> bytes,
  });

  Future<List<int>?> openDocument({required String mimeType});
}
