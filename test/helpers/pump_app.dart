import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lapse/core/theme/app_theme.dart';
import 'package:lapse/features/settings/presentation/providers/settings_providers.dart';

import 'in_memory_settings_repository.dart';

extension PumpApp on WidgetTester {
  Future<void> pumpLapse(
    Widget child, {
    Brightness brightness = Brightness.light,
    bool reduceMotion = false,
    double textScale = 1,
    bool wrapInScaffold = true,
    bool withProviders = false,
    List<Override> overrides = const [],
  }) {
    final app = MaterialApp(
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: brightness == Brightness.dark
          ? ThemeMode.dark
          : ThemeMode.light,
      builder: (context, app) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          disableAnimations: reduceMotion,
          textScaler: TextScaler.linear(textScale),
        ),
        child: app!,
      ),
      home: wrapInScaffold ? Scaffold(body: Center(child: child)) : child,
    );
    if (!withProviders) return pumpWidget(app);
    return pumpWidget(
      ProviderScope(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(
            InMemorySettingsRepository(),
          ),
          ...overrides,
        ],
        child: app,
      ),
    );
  }
}
