import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lapse/core/domain/calendar_date.dart';
import 'package:lapse/core/domain/urgency.dart';
import 'package:lapse/core/widgets/widgets.dart';
import 'package:lapse/features/home/presentation/widgets/home_hero_card.dart';
import 'package:lapse/features/subscriptions/domain/entities/billing_period.dart';
import 'package:lapse/features/subscriptions/domain/entities/subscription_status.dart';
import 'package:lapse/features/subscriptions/presentation/formatting/subscription_labels.dart';
import 'package:lapse/features/subscriptions/presentation/providers/subscription_tab.dart';
import 'package:lapse/features/subscriptions/presentation/screens/all_subscriptions_screen.dart';

import '../features/home/home_harness.dart';
import '../features/subscriptions/presentation/widgets/list/list_test_support.dart';
import '../helpers/fake_subscription_repository.dart';
import '../helpers/pump_app.dart';
import '../helpers/subscription_fixtures.dart';
import 'a11y_data.dart';

void main() {
  final today = CalendarDate(2026, 9, 18);

  group('spoken labels', () {
    test('amount reads the price with its period', () {
      expect(
        spokenAmountLabel(subscriptionFixture(priceMinor: 64900)),
        'Rs 649 monthly',
      );
      expect(
        spokenAmountLabel(
          subscriptionFixture(
            period: BillingPeriod.customDays,
            customDays: 45,
          ),
        ),
        'Rs 299 every 45 days',
      );
    });

    test('when reads as a sentence fragment', () {
      String due(int days) => spokenDueLabel(
        subscriptionFixture(nextBillingDate: today.addDays(days)),
        today,
      );
      expect(due(0), 'charges today');
      expect(due(1), 'charges tomorrow');
      expect(due(3), 'charges in 3 days');
      expect(due(10), 'charges on Sep 28');
      expect(due(-2), 'payment due');
    });

    test('cancelled rows say since when', () {
      final cancelled = subscriptionFixture(
        status: SubscriptionStatus.cancelled,
      ).copyWith(cancelledAt: DateTime(2026, 9, 12, 12));
      expect(spokenCancelledLabel(cancelled), 'since 12 Sep');
      expect(spokenCancelledLabel(subscriptionFixture()), isEmpty);
    });
  });

  testWidgets('the tile reads name, state, amount, then when', (tester) async {
    await tester.pumpLapse(
      SubscriptionListTile(
        name: 'Netflix',
        meta: 'Rs 649 after trial',
        dueLabel: 'Tomorrow',
        urgency: Urgency.urgent,
        isTrial: true,
        semanticAmount: 'Rs 649 monthly',
        semanticWhen: 'charges tomorrow',
        onTap: () {},
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    expect(
      tester.getSemantics(find.byType(SubscriptionListTile)),
      matchesSemantics(
        label: 'Netflix, free trial, Rs 649 monthly, charges tomorrow',
        isButton: true,
        hasTapAction: true,
      ),
    );
  });

  testWidgets('the tile falls back to its visible text', (tester) async {
    await tester.pumpLapse(
      const SubscriptionListTile(
        name: 'Spotify',
        meta: 'Rs 299 · Monthly',
        dueLabel: 'In 3 days',
        urgency: Urgency.warning,
      ),
    );

    expect(
      find.bySemanticsLabel('Spotify, Rs 299 · Monthly, In 3 days'),
      findsOneWidget,
    );
  });

  testWidgets('a ring can carry its meaning', (tester) async {
    await tester.pumpLapse(
      const CountdownRing(
        progress: 0.4,
        color: Colors.indigo,
        semanticLabel: '3 days left',
        child: Text('3'),
      ),
    );

    expect(find.bySemanticsLabel('3 days left'), findsOneWidget);
    expect(find.bySemanticsLabel('3'), findsNothing);
  });

  testWidgets('the savings pill reads without its emoji', (tester) async {
    await tester.pumpLapse(
      const SavingsPill(
        label: 'Saved Rs 7,788 🎉',
        semanticLabel: 'Saved Rs 7,788',
      ),
    );

    expect(find.bySemanticsLabel('Saved Rs 7,788'), findsOneWidget);
  });

  testWidgets('urgency chips read their words', (tester) async {
    await tester.pumpLapse(
      const UrgencyChip(label: 'Tomorrow', urgency: Urgency.urgent),
    );
    await tester.pump(const Duration(seconds: 1));

    expect(find.bySemanticsLabel('Tomorrow'), findsOneWidget);
  });

  testWidgets('Home reads the hero total and rows in full', (tester) async {
    await pumpHome(tester, subscriptions: homeSubscriptions());

    expect(find.bySemanticsLabel('This month, Rs 6,548'), findsOneWidget);
    expect(find.bySemanticsLabel('Rs 78,966 per year'), findsOneWidget);
    expect(find.bySemanticsLabel('Saved Rs 13,200 per year'), findsOneWidget);
    expect(
      find.bySemanticsLabel(
        'Netflix, free trial, Rs 649 monthly, charges tomorrow',
      ),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel('ChatGPT Plus, Rs 5,600 monthly, charges tomorrow'),
      findsOneWidget,
    );
  });

  testWidgets('the hero carries white text at full opacity', (tester) async {
    await pumpHome(tester, subscriptions: homeSubscriptions());

    final texts = find.descendant(
      of: find.byType(HomeHeroCard),
      matching: find.byType(Text),
    );
    expect(texts, findsWidgets);
    for (final element in texts.evaluate()) {
      final text = element.widget as Text;
      final color = text.style?.color;
      if (color == null) continue;
      if (color.a < 1) fail('"${text.data}" is not fully opaque');
    }
  });

  for (final (tab, label) in [
    (SubscriptionTab.trials, 'Disney Plus, free trial, Rs 649 monthly'),
    (
      SubscriptionTab.cancelled,
      'Hulu, cancelled, Rs 299 monthly, since 12 Sep',
    ),
  ]) {
    testWidgets('${tab.name} rows read in the same order', (tester) async {
      tester.usePhoneSize();
      await tester.pumpListScreen(
        AllSubscriptionsScreen(initialTab: tab),
        repository: FakeSubscriptionRepository()..seed(seededSubscriptions()),
      );

      expect(
        find.bySemanticsLabel(RegExp('^${RegExp.escape(label)}')),
        findsOneWidget,
      );
    });
  }
}
