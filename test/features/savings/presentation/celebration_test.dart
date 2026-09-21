import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lapse/core/providers/clock_providers.dart';
import 'package:lapse/features/savings/presentation/celebration.dart';
import 'package:lapse/features/savings/presentation/widgets/celebration_sheet.dart';
import 'package:lapse/features/subscriptions/domain/entities/subscription_status.dart';
import 'package:lapse/features/subscriptions/presentation/providers/subscription_service_providers.dart';

import '../../../helpers/fake_subscription_repository.dart';
import '../../../helpers/pump_app.dart';
import '../../../helpers/subscription_fixtures.dart';
import '../../../helpers/test_clock.dart';

const _stays = 'It stays in the Cancelled tab in case you want it back.';

void main() {
  late FakeSubscriptionRepository repository;
  late List<MethodCall> platformCalls;
  late List<Object?> announcements;

  setUp(() {
    repository = FakeSubscriptionRepository()
      ..seed([subscriptionFixture(priceMinor: 64900)]);
    platformCalls = [];
    announcements = [];
  });

  Future<void> run(
    WidgetTester tester, {
    bool reduceMotion = false,
    Brightness brightness = Brightness.light,
    double textScale = 1,
  }) async {
    tester.view
      ..physicalSize = const Size(390, 844)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final messenger = tester.binding.defaultBinaryMessenger
      ..setMockMethodCallHandler(SystemChannels.platform, (call) async {
        platformCalls.add(call);
        return null;
      })
      ..setMockDecodedMessageHandler<Object?>(
        SystemChannels.accessibility,
        (message) async {
          announcements.add(message);
          return null;
        },
      );
    addTearDown(() {
      messenger
        ..setMockMethodCallHandler(SystemChannels.platform, null)
        ..setMockDecodedMessageHandler<Object?>(
          SystemChannels.accessibility,
          null,
        );
    });
    await tester.pumpLapse(
      Consumer(
        builder: (context, ref, _) => TextButton(
          onPressed: () => markCancelledWithCelebration(
            context,
            ref,
            repository.subscriptions['sub-1']!,
          ),
          child: const Text('Run'),
        ),
      ),
      withProviders: true,
      reduceMotion: reduceMotion,
      brightness: brightness,
      textScale: textScale,
      overrides: [
        subscriptionRepositoryProvider.overrideWithValue(repository),
        clockProvider.overrideWithValue(
          TestClock(DateTime(2026, 9, 18, 10)).call,
        ),
      ],
    );
    await tester.tap(find.text('Run'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  List<String> announced() => [
    for (final message in announcements)
      if (message is Map && message['type'] == 'announce')
        (message['data'] as Map)['message'] as String,
  ];

  testWidgets('cancels and celebrates with the saving', (tester) async {
    await run(tester);
    await settle(tester);

    expect(repository.subscriptions['sub-1']!.isCancelled, isTrue);
    expect(find.byType(CelebrationSheet), findsOneWidget);
    expect(find.text('Spotify Premium cancelled'), findsOneWidget);
    expect(find.text('Rs 7,788'), findsOneWidget);
    expect(
      find.text("That's your first cancellation this year. $_stays"),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('Close'), findsNothing);
  });

  testWidgets('counts the cancellations of this year', (tester) async {
    repository.seed([
      subscriptionFixture(
        id: 'old',
        status: SubscriptionStatus.cancelled,
      ).copyWith(cancelledAt: DateTime(2025, 12, 31, 12)),
      subscriptionFixture(
        id: 'a',
        status: SubscriptionStatus.cancelled,
      ).copyWith(cancelledAt: DateTime(2026, 1, 1, 12)),
      subscriptionFixture(
        id: 'b',
        status: SubscriptionStatus.cancelled,
      ).copyWith(cancelledAt: DateTime(2026, 6, 3, 12)),
      subscriptionFixture(id: 'restored'),
    ]);
    await run(tester);
    await settle(tester);

    expect(
      find.text("That's your third cancellation this year. $_stays"),
      findsOneWidget,
    );
  });

  testWidgets('trials say which charge was dodged', (tester) async {
    repository.seed([subscriptionFixture(priceMinor: 64900, isTrial: true)]);
    await run(tester);
    await settle(tester);

    expect(find.text('Spotify Premium trial cancelled'), findsOneWidget);
    expect(
      find.text("You won't be charged Rs 649 on Thu, 1 Oct. $_stays"),
      findsOneWidget,
    );
  });

  testWidgets('Done closes and keeps it cancelled', (tester) async {
    await run(tester);
    await settle(tester);

    await tester.tap(find.text('Done'));
    await settle(tester);

    expect(find.byType(CelebrationSheet), findsNothing);
    expect(repository.subscriptions['sub-1']!.isCancelled, isTrue);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('Undo restores and confirms', (tester) async {
    await run(tester);
    await settle(tester);

    await tester.tap(find.text('Undo'));
    await settle(tester);

    expect(find.byType(CelebrationSheet), findsNothing);
    expect(repository.subscriptions['sub-1']!.isActive, isTrue);
    expect(find.text('Spotify Premium restored'), findsOneWidget);
  });

  testWidgets('dragging the sheet down counts as Done', (tester) async {
    await run(tester);
    await settle(tester);

    await tester.drag(find.text('Nice move.'), const Offset(0, 600));
    await settle(tester);

    expect(find.byType(CelebrationSheet), findsNothing);
    expect(repository.subscriptions['sub-1']!.isCancelled, isTrue);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('tapping outside counts as Done', (tester) async {
    await run(tester);
    await settle(tester);

    await tester.tapAt(const Offset(20, 20));
    await settle(tester);

    expect(find.byType(CelebrationSheet), findsNothing);
    expect(repository.subscriptions['sub-1']!.isCancelled, isTrue);
  });

  testWidgets('buzzes and announces the saving', (tester) async {
    await run(tester);

    expect(
      platformCalls.where(
        (call) =>
            call.method == 'HapticFeedback.vibrate' &&
            call.arguments == 'HapticFeedbackType.mediumImpact',
      ),
      hasLength(1),
    );
    expect(announced(), [
      'Spotify Premium cancelled. Saving Rs 7,788 per year.',
    ]);
  });

  testWidgets('reduce motion skips the haptic and the confetti', (
    tester,
  ) async {
    await run(tester, reduceMotion: true);

    expect(
      platformCalls.where((call) => call.method == 'HapticFeedback.vibrate'),
      isEmpty,
    );
    expect(announced(), hasLength(1));
    expect(find.text('Rs 7,788'), findsOneWidget);
    final sheet = tester.widget<CelebrationSheet>(
      find.byType(CelebrationSheet),
    );
    expect(sheet.playConfetti, isFalse);
  });

  for (final brightness in Brightness.values) {
    testWidgets('fits at text scale 2 in ${brightness.name}', (tester) async {
      await run(tester, brightness: brightness, textScale: 2);
      await settle(tester);

      expect(tester.takeException(), isNull);
      await tester.dragUntilVisible(
        find.text('Undo'),
        find.byType(SingleChildScrollView),
        const Offset(0, -100),
      );
      await tester.tap(find.text('Undo'));
      await settle(tester);
      expect(repository.subscriptions['sub-1']!.isActive, isTrue);
    });
  }
}
