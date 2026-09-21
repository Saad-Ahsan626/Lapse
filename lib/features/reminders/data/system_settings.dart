import 'package:flutter/services.dart';

const systemSettingsChannel = MethodChannel('lapse/system');

Future<void> openNotificationSettings() async {
  try {
    await systemSettingsChannel.invokeMethod<void>('openNotificationSettings');
  } on MissingPluginException {
    return;
  }
}
