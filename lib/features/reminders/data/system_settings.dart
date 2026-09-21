import 'package:flutter/services.dart';
import 'package:lapse/core/platform/method_channel_system_bridge.dart';

const MethodChannel systemSettingsChannel = systemChannel;

Future<void> openNotificationSettings() =>
    const MethodChannelSystemBridge().openNotificationSettings();
