import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lapse/app/router/app_router.dart';
import 'package:lapse/core/theme/app_theme.dart';
import 'package:lapse/core/widgets/subscription/service_tile.dart';

const _tag = 'tile-netflix';

void main() {
  late List<Page<void>> pages;

  Future<GoRouter> pumpRouter(
    WidgetTester tester, {
    bool reduceMotion = false,
  }) async {
    pages = [];
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: ServiceTile(name: 'Netflix', heroTag: _tag),
            ),
          ),
          routes: [
            GoRoute(
              path: 'subscription/:id',
              pageBuilder: (context, state) {
                final page = detailPage(
                  context,
                  state,
                  const Scaffold(
                    body: Center(
                      child: ServiceTile(
                        name: 'Netflix',
                        size: 64,
                        heroTag: _tag,
                      ),
                    ),
                  ),
                );
                pages.add(page);
                return page;
              },
              routes: [
                GoRoute(
                  path: 'edit',
                  builder: (_, _) => const Scaffold(body: Text('Editing')),
                ),
              ],
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MaterialApp.router(
        theme: AppTheme.light(),
        routerConfig: router,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(disableAnimations: reduceMotion),
          child: child!,
        ),
      ),
    );
    return router;
  }

  Finder shuttle() => find.byWidgetPredicate(
    (w) => w is ServiceTile && w.heroTag == null,
  );

  double radiusOf(WidgetTester tester, Finder tile) {
    final container = tester.widget<Container>(
      find.descendant(of: tile, matching: find.byType(Container)).first,
    );
    final decoration = container.decoration! as BoxDecoration;
    return (decoration.borderRadius! as BorderRadius).topLeft.x;
  }

  testWidgets('the detail page fades and slides over 320ms', (tester) async {
    final router = await pumpRouter(tester);
    unawaited(router.push('/subscription/netflix'));
    await tester.pump();

    final page = pages.last as CustomTransitionPage<void>;
    expect(page.transitionDuration, const Duration(milliseconds: 320));
    expect(page.reverseTransitionDuration, const Duration(milliseconds: 320));

    await tester.pump(const Duration(milliseconds: 160));
    final fade = tester.widget<FadeTransition>(
      find
          .ancestor(
            of: find.byType(Scaffold).last,
            matching: find.byType(FadeTransition),
          )
          .first,
    );
    expect(fade.opacity.value, inExclusiveRange(0, 1));
    final slide = tester.widget<SlideTransition>(
      find
          .ancestor(
            of: find.byType(Scaffold).last,
            matching: find.byType(SlideTransition),
          )
          .first,
    );
    expect(slide.position.value.dy, inExclusiveRange(0, detailSlideOffset.dy));

    await tester.pump(const Duration(milliseconds: 170));
    expect(shuttle(), findsNothing);
    expect(tester.getSize(find.byType(ServiceTile)), const Size(64, 64));
  });

  testWidgets('the tile flies with matched size and radius', (tester) async {
    final router = await pumpRouter(tester);
    expect(
      radiusOf(tester, find.byType(ServiceTile)),
      closeTo(44 * 0.3, 1e-9),
    );

    unawaited(router.push('/subscription/netflix'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 160));

    expect(shuttle(), findsOneWidget);
    final size = tester.getSize(shuttle());
    expect(size.width, inExclusiveRange(44, 64));
    expect(size.height, size.width);
    expect(radiusOf(tester, shuttle()), closeTo(size.width * 0.3, 1e-9));

    await tester.pump(const Duration(milliseconds: 170));
    expect(shuttle(), findsNothing);
    expect(
      radiusOf(tester, find.byType(ServiceTile)),
      closeTo(64 * 0.3, 1e-9),
    );
  });

  testWidgets('the edit child route still opens', (tester) async {
    final router = await pumpRouter(tester);
    unawaited(router.push('/subscription/netflix'));
    await tester.pumpAndSettle();
    unawaited(router.push('/subscription/netflix/edit'));
    await tester.pumpAndSettle();

    expect(find.text('Editing'), findsOneWidget);
  });

  testWidgets('reduce motion opens the detail page instantly', (
    tester,
  ) async {
    final router = await pumpRouter(tester, reduceMotion: true);
    unawaited(router.push('/subscription/netflix'));
    await tester.pump();

    final page = pages.last as CustomTransitionPage<void>;
    expect(page.transitionDuration, Duration.zero);
    expect(page.reverseTransitionDuration, Duration.zero);
    await tester.pump();
    expect(shuttle(), findsNothing);
    expect(tester.getSize(find.byType(ServiceTile).last), const Size(64, 64));
  });
}
