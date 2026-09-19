import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:lapse/app/router/routes.dart';
import 'package:lapse/features/debug/presentation/screens/data_inspector_screen.dart';
import 'package:lapse/features/debug/presentation/screens/design_gallery_screen.dart';
import 'package:lapse/features/placeholders/presentation/screens/placeholder_screen.dart';
import 'package:lapse/features/subscriptions/presentation/form/subscription_form_args.dart';
import 'package:lapse/features/subscriptions/presentation/screens/add_edit_subscription_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: Routes.home,
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
  GoRoute(
    path: Routes.home,
    builder: (_, _) => const PlaceholderScreen(
      title: 'Home',
      designRef: '05',
      phase: 3,
      showRouteLinks: true,
    ),
  ),
  GoRoute(
    path: Routes.subscriptions,
    builder: (_, _) => const PlaceholderScreen(
      title: 'All subscriptions',
      designRef: '09',
      phase: 3,
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
    builder: (_, state) => PlaceholderScreen(
      title: 'Subscription ${state.pathParameters['id']}',
      designRef: '08',
      phase: 3,
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
    path: Routes.settings,
    builder: (_, _) =>
        const PlaceholderScreen(title: 'Settings', designRef: '11', phase: 7),
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
