import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lapse/core/domain/calendar_date.dart';
import 'package:lapse/core/widgets/widgets.dart';
import 'package:lapse/features/home/presentation/widgets/home_hero_card.dart';
import 'package:lapse/features/home/presentation/widgets/trial_card.dart';
import 'package:lapse/features/subscriptions/domain/entities/billing_period.dart';
import 'package:lapse/features/subscriptions/domain/entities/subscription.dart';
import 'package:lapse/features/subscriptions/domain/entities/subscription_status.dart';

import '../../../../helpers/subscription_fixtures.dart';
import '../../home_harness.dart';

List<Subscription> populated({
  bool withCancelled = true,
  bool withUsd = true,
}) => [
  subscriptionFixture(
    id: 'spotify',
    nextBillingDate: CalendarDate(2026, 9, 25),
  ),
  subscriptionFixture(
    id: 'chatgpt',
    name: 'ChatGPT Plus',
    priceMinor: 560000,
    nextBillingDate: CalendarDate(2026, 9, 21),
  ),
  subscriptionFixture(
    id: 'icloud',
    name: 'iCloud+ 200GB',
    priceMinor: 39000,
    nextBillingDate: CalendarDate(2026, 10, 24),
  ),
  subscriptionFixture(
    id: 'netflix',
    name: 'Netflix',
    priceMinor: 64900,
    isTrial: true,
    nextBillingDate: CalendarDate(2026, 9, 19),
  ),
  if (withCancelled)
    subscriptionFixture(
      id: 'canva',
      name: 'Canva Pro',
      priceMinor: 110000,
      status: SubscriptionStatus.cancelled,
      nextBillingDate: CalendarDate(2026, 9, 30),
    ),
  if (withUsd)
    subscriptionFixture(
      id: 'github',
      name: 'GitHub',
      priceMinor: 1299,
      currency: 'USD',
      period: BillingPeriod.yearly,
      nextBillingDate: CalendarDate(2027, 3, 1),
    ),
];

void main() {
  group('populated', () {
    testWidgets('shows the month total, yearly total and savings', (
      tester,
    ) async {
      await pumpHome(tester, subscriptions: populated());

      expect(find.text('Rs 6,548'), findsOneWidget);
      expect(find.text('Rs 83,256 / year'), findsOneWidget);
      expect(find.text('Saved Rs 13,200 🎉'), findsOneWidget);
      expect(
        find.text(r'+ $12.99/yr in other currencies'),
        findsOneWidget,
      );
      expect(find.byType(LapseFab), findsOneWidget);
    });

    testWidgets('hides the savings pill and currency line when not needed', (
      tester,
    ) async {
      await pumpHome(
        tester,
        subscriptions: populated(withCancelled: false, withUsd: false),
      );

      expect(find.text('Rs 6,548'), findsOneWidget);
      expect(find.textContaining('Saved'), findsNothing);
      expect(find.textContaining('other currencies'), findsNothing);
    });

    test('joins several other currencies', () {
      expect(
        HomeHeroCard.otherCurrenciesLabel({
          'USD': populated().last.price,
          'EUR': subscriptionFixture(priceMinor: 500, currency: 'EUR').price,
        }),
        contains(' · '),
      );
    });

    testWidgets('shows the trials strip and upcoming charges this month', (
      tester,
    ) async {
      await pumpHome(tester, subscriptions: populated());

      expect(find.text('Trials ending soon'), findsOneWidget);
      expect(find.byType(TrialCard), findsOneWidget);
      expect(find.text('Rs 649 after trial'), findsOneWidget);
      expect(find.text('Upcoming charges'), findsOneWidget);
      expect(find.text('This month'), findsNWidgets(2));
      expect(find.text('ChatGPT Plus'), findsOneWidget);
      expect(find.text('Spotify Premium'), findsOneWidget);
      expect(find.text('iCloud+ 200GB'), findsNothing);
    });

    testWidgets('hides the trials strip without trials', (tester) async {
      await pumpHome(
        tester,
        subscriptions: populated().where((s) => !s.isTrial).toList(),
      );

      expect(find.text('Trials ending soon'), findsNothing);
      expect(find.byType(TrialCard), findsNothing);
    });

    testWidgets('falls back to "Coming up" when nothing is due this month', (
      tester,
    ) async {
      await pumpHome(
        tester,
        subscriptions: [
          subscriptionFixture(
            id: 'icloud',
            name: 'iCloud+',
            nextBillingDate: CalendarDate(2026, 10, 24),
          ),
        ],
      );

      expect(find.text('Coming up'), findsOneWidget);
      expect(find.text('Upcoming charges'), findsNothing);
      expect(find.text('iCloud+'), findsOneWidget);
    });

    testWidgets('says nothing else is coming when only trials exist', (
      tester,
    ) async {
      await pumpHome(
        tester,
        subscriptions: populated().where((s) => s.isTrial).toList(),
      );

      expect(find.text('No other charges coming up'), findsOneWidget);
    });

    testWidgets('uses the shared hero tag on tiles', (tester) async {
      await pumpHome(tester, subscriptions: populated());

      final tags = tester
          .widgetList<Hero>(find.byType(Hero))
          .map((hero) => hero.tag)
          .toSet();
      expect(tags, containsAll(['tile-netflix', 'tile-chatgpt']));
    });
  });

  group('navigation', () {
    testWidgets('tapping an upcoming row opens its detail', (tester) async {
      final harness = await pumpHome(tester, subscriptions: populated());

      await tester.tap(find.text('ChatGPT Plus'));
      await settleHome(tester);

      expect(harness.pushed, ['/subscription/chatgpt']);
    });

    testWidgets('tapping a trial card opens its detail', (tester) async {
      final harness = await pumpHome(tester, subscriptions: populated());

      await tester.tap(find.text('Netflix'));
      await settleHome(tester);

      expect(harness.pushed, ['/subscription/netflix']);
    });

    testWidgets('See all opens the trials tab', (tester) async {
      final harness = await pumpHome(tester, subscriptions: populated());

      await tester.tap(find.text('See all'));
      await settleHome(tester);

      expect(harness.pushed, ['/subscriptions?tab=trials']);
    });

    testWidgets('the settings button opens settings', (tester) async {
      final harness = await pumpHome(tester, subscriptions: populated());

      await tester.tap(find.bySemanticsLabel('Settings'));
      await settleHome(tester);

      expect(harness.pushed, ['/settings']);
    });

    testWidgets('the footer opens all subscriptions', (tester) async {
      final harness = await pumpHome(tester, subscriptions: populated());

      final footer = find.text('All subscriptions');
      await tester.ensureVisible(footer);
      await tester.tap(footer);
      await settleHome(tester);

      expect(harness.pushed, ['/subscriptions']);
    });

    testWidgets('the FAB opens the catalog picker', (tester) async {
      await pumpHome(tester, subscriptions: populated());

      await tester.tap(find.byType(LapseFab));
      await settleHome(tester);

      expect(find.text('Add subscription'), findsOneWidget);
    });
  });

  group('greeting', () {
    testWidgets('shows the greeting and the name', (tester) async {
      await pumpHome(tester, subscriptions: populated());

      expect(find.text('Good evening,'), findsOneWidget);
      expect(find.text('Ayesha'), findsOneWidget);
    });

    testWidgets('shows only the greeting without a name', (tester) async {
      await pumpHome(
        tester,
        subscriptions: populated(),
        userName: null,
        now: DateTime(2026, 9, 18, 8),
      );

      expect(find.text('Good morning'), findsOneWidget);
      expect(find.text('Good morning,'), findsNothing);
    });
  });

  group('states', () {
    testWidgets('empty state opens the catalog picker', (tester) async {
      await pumpHome(tester);

      expect(find.text('Nothing charging yet'), findsOneWidget);
      expect(find.text('Good evening,'), findsOneWidget);
      expect(find.text('Import a backup'), findsNothing);
      expect(find.byType(LapseFab), findsNothing);

      await tester.tap(find.text('Add your first subscription'));
      await settleHome(tester);

      expect(find.text('Add subscription'), findsOneWidget);
    });

    testWidgets('the illustration tile also opens the picker', (
      tester,
    ) async {
      await pumpHome(tester);

      await tester.tap(find.byIcon(Icons.add_rounded));
      await settleHome(tester);

      expect(find.text('Add subscription'), findsOneWidget);
    });

    testWidgets('shows skeletons while loading', (tester) async {
      await pumpHome(tester, repository: SilentSubscriptionRepository());

      expect(find.byType(SkeletonRow), findsNWidgets(3));
      expect(find.text('Good evening,'), findsOneWidget);
      expect(find.text('Nothing charging yet'), findsNothing);
    });

    testWidgets('shows an error with retry', (tester) async {
      await pumpHome(tester, repository: FailingSubscriptionRepository());

      expect(find.text("Couldn't load your subscriptions"), findsOneWidget);
      await tester.tap(find.text('Retry'));
      await settleHome(tester);
      expect(find.text("Couldn't load your subscriptions"), findsOneWidget);
    });
  });

  group('text scale 2', () {
    for (final brightness in Brightness.values) {
      testWidgets('populated does not overflow in ${brightness.name}', (
        tester,
      ) async {
        await pumpHome(
          tester,
          subscriptions: populated(),
          brightness: brightness,
          textScale: 2,
        );

        expect(tester.takeException(), isNull);
        expect(find.text('Rs 6,548'), findsOneWidget);
      });

      testWidgets('empty does not overflow in ${brightness.name}', (
        tester,
      ) async {
        await pumpHome(tester, brightness: brightness, textScale: 2);

        expect(tester.takeException(), isNull);
        expect(find.text('Nothing charging yet'), findsOneWidget);
      });
    }
  });
}
