import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:lapse/core/platform/system_bridge_provider.dart';
import 'package:lapse/core/providers/clock_providers.dart';
import 'package:lapse/features/settings/domain/entities/app_settings.dart';
import 'package:lapse/features/settings/presentation/providers/settings_providers.dart';
import 'package:lapse/features/subscriptions/domain/repositories/subscription_repository.dart';
import 'package:lapse/features/subscriptions/presentation/providers/subscription_service_providers.dart';

import '../../helpers/fake_system_bridge.dart';
import '../../helpers/in_memory_settings_repository.dart';
import '../../helpers/test_clock.dart';

final backupNow = DateTime(2026, 9, 21, 23, 30);

AppSettings startingSettings() => AppSettings(
  defaultCurrency: 'PKR',
  onboardingDone: true,
  remindersPromptSnoozedUntil: DateTime.utc(2026, 9, 25),
);

List<Override> backupOverrides({
  required SubscriptionRepository repository,
  required FakeSystemBridge bridge,
  required InMemorySettingsRepository settings,
  TestClock? clock,
}) => [
  subscriptionRepositoryProvider.overrideWithValue(repository),
  systemBridgeProvider.overrideWithValue(bridge),
  settingsRepositoryProvider.overrideWithValue(settings),
  clockProvider.overrideWithValue((clock ?? TestClock(backupNow)).call),
  newIdProvider.overrideWithValue(SequentialIds().call),
];

ProviderContainer backupContainer({
  required SubscriptionRepository repository,
  required FakeSystemBridge bridge,
  required InMemorySettingsRepository settings,
  TestClock? clock,
}) => ProviderContainer(
  overrides: backupOverrides(
    repository: repository,
    bridge: bridge,
    settings: settings,
    clock: clock,
  ),
);

class ThrowingSystemBridge extends FakeSystemBridge {
  @override
  Future<bool> saveDocument({
    required String fileName,
    required String mimeType,
    required List<int> bytes,
  }) => Future.error(PlatformException(code: 'write_failed'));

  @override
  Future<List<int>?> openDocument({required String mimeType}) {
    documentsRequested++;
    return Future.error(PlatformException(code: 'unavailable'));
  }
}
