import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lapse/app/providers/theme_mode_provider.dart';
import 'package:lapse/app/router/routes.dart';
import 'package:lapse/core/platform/system_bridge_provider.dart';
import 'package:lapse/core/providers/storage_providers.dart';
import 'package:lapse/core/theme/app_theme.dart';
import 'package:lapse/features/reminders/application/reminder_providers.dart';
import 'package:lapse/features/settings/domain/entities/app_settings.dart';
import 'package:lapse/features/settings/domain/entities/app_theme_mode.dart';
import 'package:lapse/features/settings/presentation/screens/notification_troubleshooting_screen.dart';
import 'package:lapse/features/settings/presentation/screens/settings_screen.dart';
import 'package:lapse/features/subscriptions/domain/entities/subscription.dart';

import '../../../helpers/fake_notification_gateway.dart';
import '../../../helpers/fake_system_bridge.dart';
import '../../../helpers/in_memory_settings_repository.dart';
import '../../reminders/application/reminder_test_support.dart';

Future<void> settle(WidgetTester tester, [int frames = 8]) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

class SettingsHarness {
  SettingsHarness({
    FakeNotificationGateway? gateway,
    FakeSystemBridge? bridge,
    AppSettings? settings,
    List<Subscription> subscriptions = const [],
  }) : bridge = bridge ?? FakeSystemBridge(),
       reminders = ReminderHarness(
         gateway: gateway,
         settings: InMemorySettingsRepository(
           settings ??
               AppSettings(
                 defaultCurrency: 'PKR',
                 themeMode: AppThemeMode.light,
               ),
         ),
       ) {
    reminders.repository.seed(subscriptions);
  }

  final FakeSystemBridge bridge;
  final ReminderHarness reminders;
  final List<String> pushed = [];
  late ProviderContainer container;
  late GoRouter router;

  FakeNotificationGateway get gateway => reminders.gateway;
  InMemorySettingsRepository get settings => reminders.settings;
  RecordingLinkOpener get linkOpener => reminders.linkOpener;

  Future<void> pump(
    WidgetTester tester, {
    String initialLocation = Routes.settings,
    double textScale = 1,
    Widget settingsScreen = const SettingsScreen(),
    Size size = const Size(390, 844),
    bool keepSyncAlive = false,
  }) async {
    tester.view
      ..physicalSize = size
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    container = reminders.container([
      systemBridgeProvider.overrideWithValue(bridge),
      deviceCountryProvider.overrideWithValue('PK'),
    ]);
    addTearDown(container.dispose);
    if (keepSyncAlive) {
      container.listen(reminderSyncProvider, (_, _) {});
    }

    GoRoute record(String path) => GoRoute(
      path: path,
      builder: (_, state) {
        pushed.add(state.uri.path);
        return Scaffold(body: Text('route $path'));
      },
    );

    router = GoRouter(
      initialLocation: Routes.home,
      routes: [
        GoRoute(
          path: Routes.home,
          builder: (_, _) => const Scaffold(body: Text('home')),
        ),
        GoRoute(
          path: Routes.settings,
          builder: (_, _) => settingsScreen,
          routes: [
            GoRoute(
              path: 'notifications',
              builder: (_, _) => const NotificationTroubleshootingScreen(),
            ),
          ],
        ),
        record(Routes.gallery),
        record(Routes.dataInspector),
        record(Routes.splash),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: Consumer(
          builder: (context, ref, _) => MaterialApp.router(
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: ref.watch(themeModeProvider),
            routerConfig: router,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(textScale)),
              child: child!,
            ),
          ),
        ),
      ),
    );
    await settle(tester);
    if (initialLocation != Routes.home) {
      if (initialLocation == Routes.notificationTroubleshooting) {
        unawaited(router.push<void>(Routes.settings));
        await settle(tester);
      }
      unawaited(router.push<void>(initialLocation));
      await settle(tester);
    }
  }
}
