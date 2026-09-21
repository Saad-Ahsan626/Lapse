import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lapse/core/widgets/widgets.dart';
import 'package:lapse/features/catalog/domain/entities/catalog_service.dart';
import 'package:lapse/features/subscriptions/domain/entities/billing_period.dart';
import 'package:lapse/features/subscriptions/domain/entities/subscription.dart';
import 'package:lapse/features/subscriptions/presentation/providers/subscription_tab.dart';
import 'package:lapse/features/subscriptions/presentation/widgets/list/empty_tab.dart';
import 'package:lapse/features/subscriptions/presentation/widgets/list/sort_button.dart';
import 'package:lapse/features/subscriptions/presentation/widgets/list/subscription_row.dart';
import 'package:lapse/features/subscriptions/presentation/widgets/list/swipe_hint.dart';

import '../../../../../helpers/fake_subscription_repository.dart';
import '../../../../../helpers/pump_app.dart';
import '../../../../../helpers/subscription_fixtures.dart';
import 'list_test_support.dart';

void main() {
  group('SwipeHint', () {
    testWidgets('names the actions of each tab', (tester) async {
      await tester.pumpLapse(const SwipeHint(tab: SubscriptionTab.active));
      expect(
        find.text('Swipe a row left for Mark cancelled or Delete'),
        findsOneWidget,
      );

      await tester.pumpLapse(const SwipeHint(tab: SubscriptionTab.cancelled));
      expect(
        find.text('Swipe a row left for Restore or Delete'),
        findsOneWidget,
      );
    });
  });

  group('EmptyTab', () {
    testWidgets('active offers an add button', (tester) async {
      var added = 0;
      await tester.pumpLapse(
        EmptyTab(tab: SubscriptionTab.active, onAdd: () => added++),
      );

      expect(find.text('No active subscriptions'), findsOneWidget);
      expect(
        find.text('Add one and Lapse will keep an eye on it.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Add subscription'));
      expect(added, 1);
    });

    testWidgets('trials and cancelled have no button', (tester) async {
      await tester.pumpLapse(
        EmptyTab(tab: SubscriptionTab.trials, onAdd: () {}),
      );
      expect(find.text('No free trials running'), findsOneWidget);
      expect(find.byType(LapseButton), findsNothing);

      await tester.pumpLapse(
        EmptyTab(tab: SubscriptionTab.cancelled, onAdd: () {}),
      );
      expect(find.text('Nothing cancelled yet'), findsOneWidget);
      expect(
        find.text('Subscriptions you cancel show up here with what you saved.'),
        findsOneWidget,
      );
      expect(find.byType(LapseButton), findsNothing);
    });
  });

  group('SortButton', () {
    testWidgets('shows the current sort and selects from the sheet', (
      tester,
    ) async {
      await tester.pumpLapse(const SortButton(), withProviders: true);

      expect(find.text('Next charge'), findsOneWidget);
      expect(find.bySemanticsLabel('Sort by Next charge'), findsOneWidget);

      await tester.tap(find.text('Next charge'));
      await tester.pumpAndSettle();
      expect(find.text('Sort by'), findsOneWidget);
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);

      await tester.tap(find.text('Name'));
      await tester.pumpAndSettle();

      expect(find.text('Sort by'), findsNothing);
      expect(find.text('Name'), findsOneWidget);
      expect(find.bySemanticsLabel('Sort by Name'), findsOneWidget);
    });

    testWidgets('closing the sheet keeps the sort', (tester) async {
      await tester.pumpLapse(const SortButton(), withProviders: true);

      await tester.tap(find.text('Next charge'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Close'));
      await tester.pumpAndSettle();

      expect(find.text('Sort by'), findsNothing);
      expect(find.text('Next charge'), findsOneWidget);
    });
  });

  group('SubscriptionRow', () {
    Future<void> pumpRow(
      WidgetTester tester,
      Subscription subscription, {
      List<CatalogService> catalog = const [],
      VoidCallback? onTap,
    }) async {
      tester.usePhoneSize();
      await tester.pumpListScreen(
        Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(22),
            child: SubscriptionRow(subscription: subscription, onTap: onTap),
          ),
        ),
        repository: FakeSubscriptionRepository()..seed([subscription]),
        catalog: catalog,
      );
    }

    testWidgets('uses the catalog brand and the hero tag', (tester) async {
      final subscription = subscriptionFixture(
        id: 'n1',
        name: 'Netflix',
      ).copyWith(catalogKey: 'netflix');
      await pumpRow(
        tester,
        subscription,
        catalog: const [
          CatalogService(
            key: 'netflix',
            name: 'Netflix',
            category: 'Streaming',
            initials: 'NX',
            brandColor: 0xFFE50914,
            defaultPeriod: BillingPeriod.monthly,
          ),
        ],
      );

      expect(find.text('NX'), findsOneWidget);
      expect(find.text('Rs 299 · Monthly'), findsOneWidget);
      final hero = tester.widget<Hero>(find.byType(Hero));
      expect(hero.tag, 'tile-n1');
    });

    testWidgets('calls onTap', (tester) async {
      var taps = 0;
      await pumpRow(tester, subscriptionFixture(), onTap: () => taps++);

      await tester.tap(find.text('Spotify Premium'));
      expect(taps, 1);
    });

    testWidgets('a trial shows the after-trial price and badge', (
      tester,
    ) async {
      await pumpRow(
        tester,
        subscriptionFixture(name: 'Disney Plus', isTrial: true),
      );

      expect(find.text('Rs 299 after trial'), findsOneWidget);
      expect(find.byType(TrialBadge), findsOneWidget);
    });
  });
}
