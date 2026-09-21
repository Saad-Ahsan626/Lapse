import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lapse/features/subscriptions/presentation/providers/subscription_tab.dart';
import 'package:lapse/features/subscriptions/presentation/screens/all_subscriptions_screen.dart';

import '../../../../helpers/fake_subscription_repository.dart';
import '../widgets/list/list_test_support.dart';

void main() {
  late FakeSubscriptionRepository repository;
  late RecordedPushes pushes;

  setUp(() {
    repository = FakeSubscriptionRepository()..seed(seededSubscriptions());
    pushes = RecordedPushes();
  });

  Future<void> pumpScreen(
    WidgetTester tester, {
    SubscriptionTab initialTab = SubscriptionTab.active,
    Brightness brightness = Brightness.light,
    double textScale = 1,
    bool pushed = false,
  }) async {
    tester.usePhoneSize();
    await tester.pumpListScreen(
      AllSubscriptionsScreen(initialTab: initialTab),
      repository: repository,
      pushes: pushes,
      brightness: brightness,
      textScale: textScale,
      pushed: pushed,
    );
  }

  Finder tabLabel(String label) => find.text(label, findRichText: true);

  double topOf(WidgetTester tester, String name) =>
      tester.getTopLeft(find.text(name)).dy;

  Future<void> swipe(WidgetTester tester, String name) async {
    await tester.drag(find.text(name), const Offset(-200, 0));
    await tester.pump();
    await tester.pump(settle);
  }

  Future<void> selectTab(WidgetTester tester, String label) async {
    await tester.tap(tabLabel(label));
    await tester.pump();
    await tester.pump(settle);
  }

  testWidgets('shows the tab counts', (tester) async {
    await pumpScreen(tester);

    expect(find.text('Subscriptions'), findsOneWidget);
    expect(tabLabel('Active 3'), findsOneWidget);
    expect(tabLabel('Trials 1'), findsOneWidget);
    expect(tabLabel('Cancelled 1'), findsOneWidget);
    expect(find.text('Next charge'), findsOneWidget);
  });

  testWidgets('active tab lists active non-trial rows by next charge', (
    tester,
  ) async {
    await pumpScreen(tester);

    expect(find.text('Disney Plus'), findsNothing);
    expect(find.text('Hulu'), findsNothing);
    expect(
      topOf(tester, 'ChatGPT Plus'),
      lessThan(topOf(tester, 'Spotify Premium')),
    );
    expect(
      topOf(tester, 'Spotify Premium'),
      lessThan(topOf(tester, 'Notion Plus')),
    );
    expect(find.text('In 3 days'), findsOneWidget);
    expect(
      find.text('Swipe a row left for Mark cancelled or Delete'),
      findsOneWidget,
    );
  });

  testWidgets('starts on the tab given to the constructor', (tester) async {
    await pumpScreen(tester, initialTab: SubscriptionTab.trials);

    expect(find.text('Disney Plus'), findsOneWidget);
    expect(find.text('Rs 649 after trial'), findsOneWidget);
    expect(find.text('Spotify Premium'), findsNothing);
  });

  testWidgets('switching tabs shows the right rows', (tester) async {
    await pumpScreen(tester);

    await selectTab(tester, 'Trials 1');
    expect(find.text('Disney Plus'), findsOneWidget);
    expect(find.text('Spotify Premium'), findsNothing);

    await selectTab(tester, 'Cancelled 1');
    expect(find.text('Hulu'), findsOneWidget);
    expect(find.text('Cancelled 12 Sep'), findsOneWidget);
    expect(find.text('Disney Plus'), findsNothing);
    expect(
      find.text('Swipe a row left for Restore or Delete'),
      findsOneWidget,
    );
  });

  testWidgets('the sort sheet changes the order', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.text('Next charge'));
    await tester.pump();
    await tester.pump(settle);
    expect(find.text('Sort by'), findsOneWidget);
    await tester.tap(find.text('Price'));
    await tester.pump();
    await tester.pump(settle);

    expect(find.text('Sort by'), findsNothing);
    expect(find.text('Price'), findsOneWidget);
    expect(
      topOf(tester, 'Notion Plus'),
      lessThan(topOf(tester, 'Spotify Premium')),
    );
    expect(
      topOf(tester, 'Spotify Premium'),
      lessThan(topOf(tester, 'ChatGPT Plus')),
    );

    await tester.tap(find.text('Price'));
    await tester.pump();
    await tester.pump(settle);
    await tester.tap(find.text('Name'));
    await tester.pump();
    await tester.pump(settle);

    expect(
      topOf(tester, 'ChatGPT Plus'),
      lessThan(topOf(tester, 'Notion Plus')),
    );
    expect(
      topOf(tester, 'Notion Plus'),
      lessThan(topOf(tester, 'Spotify Premium')),
    );
  });

  testWidgets('swiping reveals the actions and Cancelled marks it', (
    tester,
  ) async {
    await pumpScreen(tester);

    expect(find.text('Cancelled'), findsNothing);
    await swipe(tester, 'Spotify Premium');
    expect(find.text('Cancelled'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);

    await tester.tap(find.text('Cancelled'));
    await tester.pump();
    await tester.pump(settle);

    expect(repository.subscriptions['spotify']!.isCancelled, isTrue);
    expect(
      find.textContaining('Spotify Premium cancelled'),
      findsOneWidget,
    );
    expect(find.text('Undo'), findsOneWidget);
    expect(tabLabel('Active 2'), findsOneWidget);
    expect(tabLabel('Cancelled 2'), findsOneWidget);

    await tester.tap(find.text('Undo'));
    await tester.pump();
    await tester.pump(settle);

    expect(repository.subscriptions['spotify']!.isActive, isTrue);
  });

  testWidgets('Delete asks first and removes on confirm', (tester) async {
    await pumpScreen(tester);

    await swipe(tester, 'Notion Plus');
    await tester.tap(find.text('Delete'));
    await tester.pump();
    await tester.pump(settle);

    expect(find.text('Delete Notion Plus?'), findsOneWidget);
    await tester.tap(find.text('Delete').last);
    await tester.pump();
    await tester.pump(settle);

    expect(repository.subscriptions.containsKey('notion'), isFalse);
    expect(find.text('Notion Plus'), findsNothing);
    expect(find.text('Notion Plus deleted'), findsOneWidget);
    expect(tabLabel('Active 2'), findsOneWidget);
  });

  testWidgets('Cancelled rows offer Restore', (tester) async {
    await pumpScreen(tester, initialTab: SubscriptionTab.cancelled);

    await swipe(tester, 'Hulu');
    expect(find.text('Restore'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);

    await tester.tap(find.text('Restore'));
    await tester.pump();
    await tester.pump(settle);

    expect(repository.subscriptions['hulu']!.isActive, isTrue);
    expect(find.text('Hulu restored'), findsOneWidget);
    expect(find.text('Nothing cancelled yet'), findsOneWidget);
  });

  testWidgets('empty tabs explain themselves', (tester) async {
    repository = FakeSubscriptionRepository();
    await pumpScreen(tester);

    expect(tabLabel('Active 0'), findsOneWidget);
    expect(find.text('No active subscriptions'), findsOneWidget);
    expect(find.textContaining('Swipe a row left'), findsNothing);

    await tester.tap(find.text('Add subscription'));
    await tester.pump();
    await tester.pump(settle);
    expect(pushes.locations, ['/subscription/new']);
  });

  testWidgets('empty trials and cancelled tabs have no button', (
    tester,
  ) async {
    repository = FakeSubscriptionRepository();
    await pumpScreen(tester, initialTab: SubscriptionTab.trials);

    expect(find.text('No free trials running'), findsOneWidget);
    expect(find.text('Add subscription'), findsNothing);

    await selectTab(tester, 'Cancelled 0');
    expect(find.text('Nothing cancelled yet'), findsOneWidget);
    expect(find.text('Add subscription'), findsNothing);
  });

  testWidgets('tapping a row opens its detail', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.text('ChatGPT Plus'));
    await tester.pump();
    await tester.pump(settle);

    expect(pushes.locations, ['/subscription/chatgpt']);
    expect(find.text('Route /subscription/chatgpt'), findsOneWidget);
  });

  testWidgets('shows a back button only when pushed', (tester) async {
    await pumpScreen(tester);
    expect(find.bySemanticsLabel('Back'), findsNothing);
  });

  testWidgets('back button pops when pushed', (tester) async {
    await pumpScreen(tester, pushed: true);

    expect(find.bySemanticsLabel('Back'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Back'));
    await tester.pump();
    await tester.pump(settle);

    expect(find.text('Open list'), findsOneWidget);
  });

  testWidgets('shows skeletons while loading', (tester) async {
    repository = _NeverLoadingRepository();
    await pumpScreen(tester);

    expect(find.bySemanticsLabel('Loading'), findsNWidgets(4));
  });

  for (final brightness in Brightness.values) {
    testWidgets('no overflow at text scale 2 in ${brightness.name}', (
      tester,
    ) async {
      await pumpScreen(tester, brightness: brightness, textScale: 2);
      expect(tester.takeException(), isNull);

      await swipe(tester, 'Spotify Premium');
      expect(find.text('Cancelled'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    for (final tab in [SubscriptionTab.trials, SubscriptionTab.cancelled]) {
      testWidgets(
        '${tab.name} rows fit at text scale 2 in ${brightness.name}',
        (tester) async {
          await pumpScreen(
            tester,
            initialTab: tab,
            brightness: brightness,
            textScale: 2,
          );
          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets('empty state fits at text scale 2 in ${brightness.name}', (
      tester,
    ) async {
      repository = FakeSubscriptionRepository();
      await pumpScreen(tester, brightness: brightness, textScale: 2);
      expect(find.text('No active subscriptions'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await selectTab(tester, 'Cancelled 0');
      expect(find.text('Nothing cancelled yet'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}

class _NeverLoadingRepository extends FakeSubscriptionRepository {
  @override
  Stream<Never> watchAll() => const Stream.empty();
}
