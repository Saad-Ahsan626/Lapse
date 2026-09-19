import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

final databaseProvider = Provider<Database>(
  (ref) => throw UnimplementedError('databaseProvider is set in bootstrap()'),
);

final sharedPreferencesProvider = Provider<SharedPreferencesWithCache>(
  (ref) => throw UnimplementedError(
    'sharedPreferencesProvider is set in bootstrap()',
  ),
);

final deviceCountryProvider = Provider<String?>(
  (ref) => PlatformDispatcher.instance.locale.countryCode,
);
