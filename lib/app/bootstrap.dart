import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lapse/core/database/app_database.dart';
import 'package:lapse/core/providers/storage_providers.dart';
import 'package:lapse/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderContainer> bootstrap() async {
  final database = await openAppDatabase();
  final preferences = await SharedPreferencesWithCache.create(
    cacheOptions: const SharedPreferencesWithCacheOptions(
      allowList: SettingsRepositoryImpl.allKeys,
    ),
  );
  return ProviderContainer(
    overrides: [
      databaseProvider.overrideWithValue(database),
      sharedPreferencesProvider.overrideWithValue(preferences),
    ],
  );
}
