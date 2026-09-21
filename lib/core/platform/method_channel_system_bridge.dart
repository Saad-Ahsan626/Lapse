import 'package:flutter/services.dart';
import 'package:lapse/core/platform/app_version.dart';
import 'package:lapse/core/platform/system_bridge.dart';

const systemChannel = MethodChannel('lapse/system');

class MethodChannelSystemBridge implements SystemBridge {
  const MethodChannelSystemBridge({MethodChannel channel = systemChannel})
    : _channel = channel;

  static const fallbackVersion = AppVersion(name: '0.0.0', build: '0');

  final MethodChannel _channel;

  @override
  Future<void> openNotificationSettings() async {
    try {
      await _channel.invokeMethod<void>('openNotificationSettings');
    } on MissingPluginException {
      return;
    }
  }

  @override
  Future<AppVersion> appVersion() async {
    try {
      final map = await _channel.invokeMapMethod<String, Object?>(
        'appVersion',
      );
      if (map == null) return fallbackVersion;
      final name = map['name'];
      final build = map['build'];
      return AppVersion(
        name: name is String && name.isNotEmpty ? name : fallbackVersion.name,
        build: build == null ? fallbackVersion.build : '$build',
      );
    } on MissingPluginException {
      return fallbackVersion;
    }
  }

  @override
  Future<bool> isIgnoringBatteryOptimizations() async {
    try {
      final value = await _channel.invokeMethod<bool>(
        'isIgnoringBatteryOptimizations',
      );
      return value ?? true;
    } on MissingPluginException {
      return true;
    }
  }

  @override
  Future<void> openBatterySettings() async {
    try {
      await _channel.invokeMethod<void>('openBatterySettings');
    } on MissingPluginException {
      return;
    }
  }

  @override
  Future<bool> saveDocument({
    required String fileName,
    required String mimeType,
    required List<int> bytes,
  }) async {
    try {
      final saved = await _channel.invokeMethod<bool>('saveDocument', {
        'fileName': fileName,
        'mimeType': mimeType,
        'bytes': bytes is Uint8List ? bytes : Uint8List.fromList(bytes),
      });
      return saved ?? false;
    } on MissingPluginException {
      return false;
    }
  }

  @override
  Future<List<int>?> openDocument({required String mimeType}) async {
    try {
      final bytes = await _channel.invokeMethod<Object?>('openDocument', {
        'mimeType': mimeType,
      });
      return switch (bytes) {
        Uint8List() => bytes,
        List<Object?>() => Uint8List.fromList(bytes.cast<int>()),
        _ => null,
      };
    } on MissingPluginException {
      return null;
    }
  }
}
