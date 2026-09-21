import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lapse/core/theme/app_theme.dart';
import 'package:lapse/features/placeholders/presentation/screens/placeholder_screen.dart';

void main() {
  Future<List<String>> pumpPlaceholder(
    WidgetTester tester, {
    required bool showDebugLinks,
  }) async {
    final visited = <String>[];
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => PlaceholderScreen(
            title: 'Settings',
            designRef: '11',
            phase: 7,
            showDebugLinks: showDebugLinks,
          ),
        ),
        GoRoute(
          path: '/debug/:page',
          builder: (_, state) {
            visited.add(state.uri.path);
            return const SizedBox();
          },
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MaterialApp.router(theme: AppTheme.light(), routerConfig: router),
    );
    return visited;
  }

  testWidgets('shows the screen name and phase', (tester) async {
    await pumpPlaceholder(tester, showDebugLinks: false);

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('DESIGN SCREEN 11 · PHASE 7'), findsOneWidget);
    expect(find.text('Open design gallery'), findsNothing);
  });

  testWidgets('debug links open the gallery and the inspector', (
    tester,
  ) async {
    final visited = await pumpPlaceholder(tester, showDebugLinks: true);

    await tester.tap(find.text('Open data inspector'));
    await tester.pumpAndSettle();

    expect(visited, ['/debug/data']);
  });
}
