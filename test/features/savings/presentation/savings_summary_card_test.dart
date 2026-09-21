import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lapse/features/savings/presentation/widgets/savings_summary_card.dart';
import 'package:lapse/features/subscriptions/domain/entities/subscription.dart';
import 'package:lapse/features/subscriptions/domain/entities/subscription_status.dart';
import 'package:lapse/features/subscriptions/presentation/providers/subscription_service_providers.dart';

import '../../../helpers/fake_subscription_repository.dart';
import '../../../helpers/pump_app.dart';
import '../../../helpers/subscription_fixtures.dart';

Subscription _cancelled(String id, int priceMinor, {String currency = 'PKR'}) =>
    subscriptionFixture(
      id: id,
      priceMinor: priceMinor,
      currency: currency,
      status: SubscriptionStatus.cancelled,
    ).copyWith(cancelledAt: DateTime.utc(2026, 9, 12));

void main() {
  Future<void> pumpCard(
    WidgetTester tester,
    List<Subscription> subscriptions, {
    Brightness brightness = Brightness.light,
    double textScale = 1,
  }) async {
    tester.view
      ..physicalSize = const Size(390, 844)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final repository = FakeSubscriptionRepository()..seed(subscriptions);
    await tester.pumpLapse(
      const Padding(
        padding: EdgeInsets.all(22),
        child: SavingsSummaryCard(),
      ),
      withProviders: true,
      brightness: brightness,
      textScale: textScale,
      overrides: [
        subscriptionRepositoryProvider.overrideWithValue(repository),
      ],
    );
    await tester.pump();
    await tester.pump();
  }

  testWidgets('sums the yearly savings of cancelled subscriptions', (
    tester,
  ) async {
    await pumpCard(tester, [
      _cancelled('a', 29900),
      _cancelled('b', 64900),
      _cancelled('c', 1000, currency: 'USD'),
      subscriptionFixture(id: 'active'),
    ]);

    expect(find.text('Saved Rs 11,376 / year'), findsOneWidget);
    expect(find.text('from 2 cancellations'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Saved Rs 11,376 per year, from 2 cancellations'),
      findsOneWidget,
    );
  });

  testWidgets('uses the singular for one cancellation', (tester) async {
    await pumpCard(tester, [_cancelled('a', 64900)]);

    expect(find.text('Saved Rs 7,788 / year'), findsOneWidget);
    expect(find.text('from 1 cancellation'), findsOneWidget);
  });

  testWidgets('is hidden when nothing is cancelled', (tester) async {
    await pumpCard(tester, [subscriptionFixture()]);

    expect(find.textContaining('Saved'), findsNothing);
  });

  testWidgets('is hidden when only other currencies are cancelled', (
    tester,
  ) async {
    await pumpCard(tester, [_cancelled('a', 1000, currency: 'USD')]);

    expect(find.textContaining('Saved'), findsNothing);
  });

  for (final brightness in Brightness.values) {
    testWidgets('fits at text scale 2 in ${brightness.name}', (tester) async {
      await pumpCard(
        tester,
        [_cancelled('a', 99999900)],
        brightness: brightness,
        textScale: 2,
      );

      expect(find.text('Saved Rs 11,999,988 / year'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
