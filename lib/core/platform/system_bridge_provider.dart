import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lapse/core/platform/method_channel_system_bridge.dart';
import 'package:lapse/core/platform/system_bridge.dart';

final systemBridgeProvider = Provider<SystemBridge>(
  (ref) => const MethodChannelSystemBridge(),
);
