import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:lapse/app/router/routes.dart';
import 'package:lapse/features/debug/presentation/screens/data_inspector_screen.dart';
import 'package:lapse/features/debug/presentation/screens/design_gallery_screen.dart';
import 'package:lapse/features/home/presentation/screens/home_screen.dart';
import 'package:lapse/features/placeholders/presentation/screens/placeholder_screen.dart';
import 'package:lapse/features/reminders/presentation/screens/reminder_permission_screen.dart';
import 'package:lapse/features/subscriptions/presentation/form/subscription_form_args.dart';
import 'package:lapse/features/subscriptions/presentation/providers/subscription_tab.dart';
import 'package:lapse/features/subscriptions/presentation/screens/add_edit_subscription_screen.dart';
import 'package:lapse/features/subscriptions/presentation/screens/all_subscriptions_screen.dart';
import 'package:lapse/features/subscriptions/presentation/screens/subscription_detail_screen.dart';

final initialLocationProvider = Provider<String>((ref) => Routes.home);

final appRouterProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: ref.watch(initialLocationProvider),
    debugLogDiagnostics: kDebugMode,
    routes: _routes,
  );
  ref.onDispose(router.dispose);
  return router;
});

String? _queryValue(GoRouterState state, String key) {
  final value = state.uri.queryParameters[key]?.trim();
  return value == null || value.isEmpty ? null : value;
}

final List<RouteBase> _routes = [
  GoRoute(
    path: Routes.splash,
    builder: (_, _) =>
        const PlaceholderScreen(title: 'Splash', designRef: '01', phase: 6),
  ),
  GoRoute(
    path: Routes.onboarding,
    builder: (_, _) =>
        const PlaceholderScreen(title: 'Onboarding', designRef: '02', phase: 6),
    routes: [
      GoRoute(
        path: 'permission',
        builder: (_, _) => const PlaceholderScreen(
          title: 'Notification permission',
          designRef: '03',
          phase: 6,
        ),
      ),
      GoRoute(
        path: 'setup',
        builder: (_, _) =>
            const PlaceholderScreen(title: 'Setup', designRef: '04', phase: 6),
      ),
    ],
  ),
  GoRoute(path: Routes.home, builder: (_, _) => const HomeScreen()),
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
    builder: (_, state) =>
        SubscriptionDetailScreen(id: state.pathParameters['id']!),
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
    builder: (_, _) => const PlaceholderScreen(
      title: 'Settings',
      designRef: '11',
      phase: 7,
      showDebugLinks: true,
    ),
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
