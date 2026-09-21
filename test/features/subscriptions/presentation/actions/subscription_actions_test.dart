import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lapse/core/providers/clock_providers.dart';
import 'package:lapse/features/subscriptions/domain/entities/subscription.dart';
import 'package:lapse/features/subscriptions/domain/entities/subscription_status.dart';
import 'package:lapse/features/subscriptions/presentation/actions/subscription_actions.dart';
import 'package:lapse/features/subscriptions/presentation/providers/subscription_service_providers.dart';

import '../../../../helpers/fake_subscription_repository.dart';
import '../../../../helpers/pump_app.dart';
import '../../../../helpers/subscription_fixtures.dart';

void main() {
  late FakeSubscriptionRepository repository;

  setUp(() {
    repository = FakeSubscriptionRepository()
      ..seed([subscriptionFixture(priceMinor: 64900)]);
  });

  Future<void> pumpAction(
    WidgetTester tester,
    Future<void> Function(BuildContext, WidgetRef, Subscription) action,
  ) async {
    await tester.pumpLapse(
      Consumer(
        builder: (context, ref, _) => TextButton(
          onPressed: () => action(
            context,
            ref,
            repository.subscriptions['sub-1']!,
          ),
          child: const Text('Run'),
        ),
      ),
      withProviders: true,
      overrides: [
        subscriptionRepositoryProvider.overrideWithValue(repository),
        clockProvider.overrideWithValue(() => DateTime(2026, 9, 18, 10)),
      ],
    );
    await tester.tap(find.text('Run'));
    await tester.pump();
    await tester.pump();
  }

  testWidgets('restore reactivates and confirms', (tester) async {
    repository.seed([
      subscriptionFixture(
        priceMinor: 64900,
        status: SubscriptionStatus.cancelled,
      ).copyWith(cancelledAt: DateTime.utc(2026, 9, 12)),
    ]);
    await pumpAction(tester, restoreWithFeedback);

    expect(repository.subscriptions['sub-1']!.isActive, isTrue);
    expect(find.text('Spotify Premium restored'), findsOneWidget);
  });

  testWidgets('delete asks first and keeps the subscription on Keep', (
    tester,
  ) async {
    await pumpAction(tester, confirmAndDelete);

    expect(find.text('Delete Spotify Premium?'), findsOneWidget);
    await tester.tap(find.text('Keep'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(repository.subscriptions, contains('sub-1'));
  });

  testWidgets('delete removes it after confirming', (tester) async {
    await pumpAction(tester, confirmAndDelete);

    await tester.tap(find.text('Delete').last);
    await tester.pump();
    await tester.pump();

    expect(repository.subscriptions, isEmpty);
    expect(find.text('Spotify Premium deleted'), findsOneWidget);
  });
}
