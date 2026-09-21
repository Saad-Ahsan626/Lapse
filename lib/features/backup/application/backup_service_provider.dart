import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lapse/core/platform/system_bridge_provider.dart';
import 'package:lapse/core/providers/clock_providers.dart';
import 'package:lapse/features/backup/application/backup_service.dart';
import 'package:lapse/features/settings/presentation/providers/settings_providers.dart';
import 'package:lapse/features/subscriptions/presentation/providers/subscription_service_providers.dart';

final backupServiceProvider = Provider<BackupService>((ref) {
  final rollOver = ref.watch(rollOverDueSubscriptionsProvider);
  return BackupService(
    repository: ref.watch(subscriptionRepositoryProvider),
    bridge: ref.watch(systemBridgeProvider),
    clock: ref.watch(clockProvider),
    readSettings: () => ref.read(settingsProvider),
    updateSettings: (change) =>
        ref.read(settingsProvider.notifier).update(change),
    rollOver: rollOver.call,
  );
});
