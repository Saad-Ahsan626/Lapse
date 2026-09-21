import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lapse/core/platform/app_version.dart';
import 'package:lapse/core/platform/system_bridge_provider.dart';

final appVersionProvider = FutureProvider<AppVersion>(
  (ref) => ref.watch(systemBridgeProvider).appVersion(),
);
