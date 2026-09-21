import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lapse/app/router/routes.dart';
import 'package:lapse/core/theme/app_theme.dart';
import 'package:lapse/core/widgets/widgets.dart';
import 'package:lapse/features/subscriptions/presentation/form/subscription_form_args.dart';
import 'package:lapse/features/subscriptions/presentation/screens/add_edit_subscription_screen.dart';
import 'package:lapse/features/subscriptions/presentation/widgets/form/details_section.dart';
import 'package:lapse/features/subscriptions/presentation/widgets/form/price_section.dart';

import '../../../../helpers/fake_subscription_repository.dart';
import '../../../../helpers/pump_app.dart';
import '../../../../helpers/subscription_fixtures.dart';
import '../form_test_support.dart';

Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

LapseButton saveButton(WidgetTester tester) =>
    tester.widget<LapseButton>(find.widgetWithText(LapseButton, 'Save'));

Finder priceField() => find.descendant(
  of: find.byType(PriceSection),
  matching: find.byType(TextField),
);

Finder rowField(String label) => find.descendant(
  of: find.widgetWithText(LapseRowField, label),
  matching: find.byType(TextField),
);

void main() {
  late FakeSubscriptionRepository repository;

  setUp(() => repository = FakeSubscriptionRepository());

  Future<void> pumpScreen(
    WidgetTester tester,
    SubscriptionFormArgs args, {
    double textScale = 1,
    bool pushed = false,
  }) async {
    await tester.binding.setSurfaceSize(const Size(400, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final screen = AddEditSubscriptionScreen(args: args);
    await tester.pumpLapse(
      pushed
          ? Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => screen),
                    ),
                    child: const Text('open'),
                  ),
                ),
              ),
            )
          : screen,
      wrapInScaffold: false,
      withProviders: true,
      textScale: textScale,
      overrides: formOverrides(repository, withSettings: false),
    );
    if (pushed) {
      await tester.tap(find.text('open'));
    }
    await settle(tester);
  }

  testWidgets('save stays disabled until a price is typed', (tester) async {
    await pumpScreen(tester, const SubscriptionFormArgs(serviceKey: 'netflix'));

    expect(find.text('Netflix'), findsOneWidget);
    expect(find.text('Entertainment'), findsWidgets);
    expect(saveButton(tester).onPressed, isNull);

    await tester.enterText(priceField(), '649');
    await tester.pump();

    expect(saveButton(tester).onPressed, isNotNull);
  });

  testWidgets('focuses the price field when opened from the catalog', (
    tester,
  ) async {
    await pumpScreen(tester, const SubscriptionFormArgs(serviceKey: 'netflix'));

    final field = tester.widget<TextField>(priceField());
    expect(field.focusNode!.hasFocus, isTrue);
  });

  testWidgets('trial switch expands the block and hides PRICE', (
    tester,
  ) async {
    await pumpScreen(tester, const SubscriptionFormArgs(serviceKey: 'netflix'));
    expect(find.text('PRICE'), findsOneWidget);
    expect(find.text('TRIAL LENGTH'), findsNothing);
    expect(find.text('NEXT BILLING DATE'), findsOneWidget);

    await tester.tap(find.byType(Switch));
    await settle(tester);

    expect(find.text('TRIAL LENGTH'), findsOneWidget);
    expect(find.text('Price after trial'), findsOneWidget);
    expect(find.text('PRICE'), findsNothing);
    expect(find.text('TRIAL ENDS'), findsOneWidget);
    expect(find.text('Fri, 25 Sep 2026'), findsOneWidget);
    expect(find.byType(TrialBadge), findsOneWidget);

    await tester.tap(find.text('14d'));
    await tester.pump();
    expect(find.text('Fri, 2 Oct 2026'), findsOneWidget);
  });

  testWidgets('validation errors appear under the field', (tester) async {
    await pumpScreen(tester, const SubscriptionFormArgs(serviceKey: 'netflix'));

    await tester.enterText(priceField(), '649');
    await tester.enterText(rowField('Payment method'), '4111 1111 1111 1111');
    await tester.pump();
    await tester.tap(find.widgetWithText(LapseButton, 'Save'));
    await settle(tester);

    expect(find.text('Only add the last 4 digits'), findsOneWidget);
    expect(repository.subscriptions, isEmpty);
  });

  testWidgets('saving a new subscription lands on its detail with undo', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(400, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final router = GoRouter(
      routes: [
        GoRoute(
          path: Routes.home,
          builder: (_, _) => const Scaffold(body: Text('home')),
        ),
        GoRoute(
          path: Routes.newSubscription,
          builder: (_, _) => const AddEditSubscriptionScreen(
            args: SubscriptionFormArgs(serviceKey: 'netflix'),
          ),
        ),
        GoRoute(
          path: '/subscription/:id',
          builder: (_, state) =>
              Scaffold(body: Text('detail ${state.pathParameters['id']}')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: formOverrides(repository),
        child: MaterialApp.router(
          theme: AppTheme.light(),
          routerConfig: router,
        ),
      ),
    );
    await tester.pump();
    unawaited(router.push<void>(Routes.newSubscription));
    await settle(tester);

    await tester.enterText(priceField(), '649');
    await tester.pump();
    await tester.tap(find.widgetWithText(LapseButton, 'Save'));
    await settle(tester);

    expect(find.byType(AddEditSubscriptionScreen), findsNothing);
    expect(repository.subscriptions, hasLength(1));
    final id = repository.subscriptions.keys.single;
    expect(router.state.uri.toString(), Routes.detail(id));
    expect(find.text('detail $id'), findsOneWidget);
    expect(find.text('Netflix added'), findsOneWidget);

    await tester.tap(find.text('Undo'));
    await settle(tester);
    expect(repository.subscriptions, isEmpty);

    router.pop();
    await settle(tester);
    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('saving a new subscription without a router pops', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      const SubscriptionFormArgs(serviceKey: 'netflix'),
      pushed: true,
    );

    await tester.enterText(priceField(), '649');
    await tester.pump();
    await tester.tap(find.widgetWithText(LapseButton, 'Save'));
    await settle(tester);

    expect(find.byType(AddEditSubscriptionScreen), findsNothing);
    expect(find.text('Netflix added'), findsOneWidget);
    expect(repository.subscriptions, hasLength(1));
  });

  testWidgets('saving an edit pops without a snackbar', (tester) async {
    repository.seed([subscriptionFixture()]);
    await pumpScreen(
      tester,
      const SubscriptionFormArgs.edit('sub-1'),
      pushed: true,
    );

    await tester.tap(find.widgetWithText(LapseButton, 'Save'));
    await settle(tester);

    expect(find.byType(AddEditSubscriptionScreen), findsNothing);
    expect(find.text('open'), findsOneWidget);
    expect(find.textContaining('added'), findsNothing);
  });

  testWidgets('edit screen is prefilled', (tester) async {
    repository.seed([
      subscriptionFixture(
        cancelUrl: 'https://spotify.com/account',
      ),
    ]);
    await pumpScreen(tester, const SubscriptionFormArgs.edit('sub-1'));

    expect(find.text('Spotify Premium'), findsOneWidget);
    expect(find.text('299'), findsOneWidget);
    expect(find.text('https://spotify.com/account'), findsOneWidget);
    expect(find.text('Thu, 1 Oct 2026'), findsOneWidget);
    expect(saveButton(tester).onPressed, isNotNull);
    expect(find.byType(DetailsSection), findsOneWidget);
  });

  testWidgets('missing subscription shows a message', (tester) async {
    await pumpScreen(tester, const SubscriptionFormArgs.edit('ghost'));
    expect(find.text('This subscription no longer exists'), findsOneWidget);
  });

  testWidgets('back with changes asks to discard', (tester) async {
    await pumpScreen(
      tester,
      const SubscriptionFormArgs(serviceKey: 'netflix'),
      pushed: true,
    );

    await tester.enterText(priceField(), '649');
    await tester.pump();
    await tester.tap(find.bySemanticsLabel('Back'));
    await settle(tester);

    expect(find.text('Discard changes?'), findsOneWidget);
    await tester.tap(find.text('Keep editing'));
    await settle(tester);
    expect(find.byType(AddEditSubscriptionScreen), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Back'));
    await settle(tester);
    await tester.tap(find.text('Discard'));
    await settle(tester);
    expect(find.byType(AddEditSubscriptionScreen), findsNothing);
    expect(repository.subscriptions, isEmpty);
  });

  testWidgets('back without changes leaves at once', (tester) async {
    await pumpScreen(
      tester,
      const SubscriptionFormArgs(serviceKey: 'netflix'),
      pushed: true,
    );

    await tester.tap(find.bySemanticsLabel('Back'));
    await settle(tester);

    expect(find.text('Discard changes?'), findsNothing);
    expect(find.byType(AddEditSubscriptionScreen), findsNothing);
  });

  testWidgets('no overflow at text scale 2', (tester) async {
    await pumpScreen(
      tester,
      const SubscriptionFormArgs(serviceKey: 'netflix'),
      textScale: 2,
    );
    expect(tester.takeException(), isNull);

    await tester.tap(find.byType(Switch));
    await settle(tester);
    await tester.tap(find.text('Custom').last);
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
