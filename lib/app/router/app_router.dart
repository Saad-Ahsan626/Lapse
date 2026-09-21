import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:lapse/app/router/routes.dart';
import 'package:lapse/core/motion/motion.dart';
import 'package:lapse/features/debug/presentation/screens/data_inspector_screen.dart';
import 'package:lapse/features/debug/presentation/screens/design_gallery_screen.dart';
import 'package:lapse/features/home/presentation/screens/home_screen.dart';
import 'package:lapse/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:lapse/features/onboarding/presentation/screens/setup_screen.dart';
import 'package:lapse/features/reminders/presentation/screens/reminder_permission_screen.dart';
import 'package:lapse/features/settings/presentation/providers/settings_providers.dart';
import 'package:lapse/features/settings/presentation/screens/notification_troubleshooting_screen.dart';
import 'package:lapse/features/settings/presentation/screens/settings_screen.dart';
import 'package:lapse/features/splash/presentation/screens/splash_screen.dart';
import 'package:lapse/features/subscriptions/presentation/form/subscription_form_args.dart';
import 'package:lapse/features/subscriptions/presentation/providers/subscription_tab.dart';
import 'package:lapse/features/subscriptions/presentation/screens/add_edit_subscription_screen.dart';
import 'package:lapse/features/subscriptions/presentation/screens/all_subscriptions_screen.dart';
import 'package:lapse/features/subscriptions/presentation/screens/subscription_detail_screen.dart';

final initialLocationProvider = Provider<String>((ref) => Routes.splash);

final appRouterProvider = Provider<GoRouter>((ref) {
  final onboardingDone = ValueNotifier<bool>(
    ref.read(settingsProvider).onboardingDone,
  );
  ref.listen(
    settingsProvider.select((settings) => settings.onboardingDone),
    (_, done) => onboardingDone.value = done,
  );
  final router = GoRouter(
    initialLocation: ref.watch(initialLocationProvider),
    debugLogDiagnostics: kDebugMode,
    refreshListenable: onboardingDone,
    redirect: (_, state) => onboardingRedirect(
      state.uri.path,
      onboardingDone: onboardingDone.value,
    ),
    routes: _routes,
  );
  ref.onDispose(() {
    router.dispose();
    onboardingDone.dispose();
  });
  return router;
});

String? onboardingRedirect(
  String path, {
  required bool onboardingDone,
  bool allowDebugRoutes = kDebugMode,
}) {
  final inOnboarding =
      path == Routes.onboarding || path.startsWith('${Routes.onboarding}/');
  if (onboardingDone) return inOnboarding ? Routes.home : null;
  if (inOnboarding || path == Routes.splash) return null;
  if (allowDebugRoutes && path.startsWith('/debug/')) return null;
  return Routes.onboarding;
}

Page<void> _fadePage(GoRouterState state, Widget child) =>
    CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionDuration: Motion.expand,
      reverseTransitionDuration: Motion.fade,
      transitionsBuilder: (context, animation, _, child) =>
          reduceMotion(context)
          ? child
          : FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeOut,
              ),
              child: child,
            ),
    );

const Offset detailSlideOffset = Offset(0, 0.04);

Page<void> detailPage(BuildContext context, GoRouterState state, Widget child) {
  final instant = reduceMotion(context);
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: instant ? Duration.zero : Motion.hero,
    reverseTransitionDuration: instant ? Duration.zero : Motion.hero,
    transitionsBuilder: (context, animation, _, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Motion.emphasized,
        reverseCurve: Curves.easeIn,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: detailSlideOffset,
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}

String? _queryValue(GoRouterState state, String key) {
  final value = state.uri.queryParameters[key]?.trim();
  return value == null || value.isEmpty ? null : value;
}

final List<RouteBase> _routes = [
  GoRoute(
    path: Routes.splash,
    pageBuilder: (_, state) =>
        NoTransitionPage<void>(key: state.pageKey, child: const SplashScreen()),
  ),
  GoRoute(
    path: Routes.onboarding,
    pageBuilder: (_, state) => _fadePage(state, const OnboardingScreen()),
    routes: [
      GoRoute(path: 'setup', builder: (_, _) => const SetupScreen()),
      GoRoute(
        path: 'permission',
        builder: (_, _) => const ReminderPermissionScreen(inOnboarding: true),
      ),
    ],
  ),
  GoRoute(
    path: Routes.home,
    pageBuilder: (_, state) => _fadePage(state, const HomeScreen()),
  ),
  GoRoute(
    path: Routes.subscriptions,
    builder: (_, state) => AllSubscriptionsScreen(
      initialTab: SubscriptionTab.fromQuery(_queryValue(state, 'tab')),
    ),
  ),
  GoRoute(
    path: Routes.newSubscription,
    builder: (_, state) => AddEditSubscriptionScreen(
      args: SubscriptionFormArgs(
        serviceKey: _queryValue(state, 'service'),
        name: _queryValue(state, 'name'),
      ),
    ),
  ),
  GoRoute(
    path: '/subscription/:id',
    pageBuilder: (context, state) => detailPage(
      context,
      state,
      SubscriptionDetailScreen(id: state.pathParameters['id']!),
    ),
    routes: [
      GoRoute(
        path: 'edit',
        builder: (_, state) => AddEditSubscriptionScreen(
          args: SubscriptionFormArgs.edit(state.pathParameters['id']!),
        ),
      ),
    ],
  ),
  GoRoute(
    path: Routes.remindersPermission,
    builder: (_, _) => const ReminderPermissionScreen(),
  ),
  GoRoute(
    path: Routes.settings,
    builder: (_, _) => const SettingsScreen(),
    routes: [
      GoRoute(
        path: 'notifications',
        builder: (_, _) => const NotificationTroubleshootingScreen(),
      ),
    ],
  ),
  if (kDebugMode) ...[
    GoRoute(
      path: Routes.gallery,
      builder: (_, _) => const DesignGalleryScreen(),
    ),
    GoRoute(
      path: Routes.dataInspector,
      builder: (_, _) => const DataInspectorScreen(),
    ),
  ],
];
