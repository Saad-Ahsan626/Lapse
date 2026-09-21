import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lapse/app/router/app_router.dart';
import 'package:lapse/app/router/routes.dart';
import 'package:lapse/core/database/app_database.dart';
import 'package:lapse/core/providers/storage_providers.dart';
import 'package:lapse/features/reminders/application/reminder_providers.dart';
import 'package:lapse/features/reminders/application/reminders_bootstrap.dart';
import 'package:lapse/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:lapse/features/settings/presentation/providers/settings_providers.dart';
import 'package:lapse/features/subscriptions/presentation/providers/subscription_service_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderContainer> bootstrap() async {
  final database = await openAppDatabase();
  final preferences = await SharedPreferencesWithCache.create(
    cacheOptions: const SharedPreferencesWithCacheOptions(
      allowList: SettingsRepositoryImpl.allKeys,
    ),
  );
  var initialLocation = Routes.splash;
  final container = ProviderContainer(
    overrides: [
      databaseProvider.overrideWithValue(database),
      sharedPreferencesProvider.overrideWithValue(preferences),
      initialLocationProvider.overrideWith((ref) => initialLocation),
    ],
  );
  await skipOnboardingForExistingInstall(container);
  final launch = await bootstrapReminders(container);
  initialLocation = initialLocationFor(launch);
  if (launch != null) {
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => unawaited(
        container.read(notificationTapHandlerProvider).handleLaunch(launch),
      ),
    );
  }
  return container;
}

Future<void> skipOnboardingForExistingInstall(
  ProviderContainer container,
) async {
  try {
    if (container.read(settingsProvider).onboardingDone) return;
    final existing = await container
        .read(subscriptionRepositoryProvider)
        .getAll();
    if (existing.isEmpty) return;
    await container
        .read(settingsProvider.notifier)
        .update((settings) => settings.copyWith(onboardingDone: true));
  } on Object {
    return;
  }
}
