import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lapse/core/domain/calendar_date.dart';
import 'package:lapse/core/motion/motion.dart';
import 'package:lapse/core/widgets/widgets.dart';
import 'package:lapse/features/subscriptions/domain/entities/subscription.dart';
import 'package:lapse/features/subscriptions/presentation/screens/all_subscriptions_screen.dart';
import 'package:lapse/features/subscriptions/presentation/widgets/list/subscription_row.dart';
import 'package:lapse/features/subscriptions/presentation/widgets/list/subscriptions_top_bar.dart';

import '../../../../helpers/fake_subscription_repository.dart';
import '../../../../helpers/rebuild_counter.dart';
import '../../../../helpers/subscription_fixtures.dart';
import '../widgets/list/list_test_support.dart';

List<Subscription> manySubscriptions() => [
  ...seededSubscriptions(),
  for (var i = 0; i < 16; i++)
    subscriptionFixture(
      id: 'extra-$i',
      name: 'Extra service $i',
      nextBillingDate: CalendarDate(2026, 11, 1 + i),
    ),
];

Widget reduced(Widget child) => Builder(
  builder: (context) => MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: true),
    child: child,
  ),
);

void main() {
  late FakeSubscriptionRepository repository;

  setUp(() {
    repository = FakeSubscriptionRepository();
  });

  Future<void> pumpScreen(
    WidgetTester tester, {
    List<Subscription>? subscriptions,
    bool reduceMotion = false,
  }) async {
    repository.seed(subscriptions ?? seededSubscriptions());
    tester.usePhoneSize();
    const screen = AllSubscriptionsScreen();
    await tester.pumpListScreen(
      reduceMotion ? reduced(screen) : screen,
      repository: repository,
    );
  }

  StaggeredEntrance entranceOf(WidgetTester tester, String name) =>
      tester.widget<StaggeredEntrance>(
        find.ancestor(
          of: find.text(name),
          matching: find.byType(StaggeredEntrance),
        ),
      );

  double opacityOf(WidgetTester tester, String name) => tester
      .widget<Opacity>(
        find.ancestor(of: find.text(name), matching: find.byType(Opacity)).last,
      )
      .opacity;

  Future<void> selectTab(WidgetTester tester, String label) async {
    await tester.tap(find.text(label, findRichText: true));
    await tester.pump();
  }

  testWidgets('rows stagger in 40ms apart on first appearance', (
    tester,
  ) async {
    await pumpScreen(tester);

    final rows = tester
        .widgetList<StaggeredEntrance>(find.byType(StaggeredEntrance))
        .toList();
    expect(rows.map((r) => r.index), [0, 1, 2]);
    expect(rows.every((r) => r.animate), isTrue);
    expect(
      StaggeredEntrance.delayFor(2) - StaggeredEntrance.delayFor(1),
      const Duration(milliseconds: 40),
    );

    await tester.pump(const Duration(seconds: 1));
    expect(opacityOf(tester, 'ChatGPT Plus'), 1);
    expect(opacityOf(tester, 'Notion Plus'), 1);
  });

  testWidgets('a tab animates the first time it is shown only', (
    tester,
  ) async {
    await pumpScreen(tester);
    await tester.pump(const Duration(seconds: 1));

    await selectTab(tester, 'Trials 1');
    expect(entranceOf(tester, 'Disney Plus').animate, isTrue);
    expect(opacityOf(tester, 'Disney Plus'), lessThan(1));
    await tester.pump(const Duration(milliseconds: 225));
    expect(opacityOf(tester, 'Disney Plus'), inExclusiveRange(0, 1));
    await tester.pump(const Duration(milliseconds: 225));
    expect(opacityOf(tester, 'Disney Plus'), 1);

    await selectTab(tester, 'Active 3');
    expect(entranceOf(tester, 'ChatGPT Plus').animate, isFalse);
    expect(opacityOf(tester, 'ChatGPT Plus'), 1);

    await selectTab(tester, 'Trials 1');
    expect(entranceOf(tester, 'Disney Plus').animate, isFalse);
    expect(opacityOf(tester, 'Disney Plus'), 1);
  });

  testWidgets('the stagger stops after eight rows and never on scroll', (
    tester,
  ) async {
    await pumpScreen(tester, subscriptions: manySubscriptions());

    final first = tester
        .widgetList<StaggeredEntrance>(find.byType(StaggeredEntrance))
        .toList();
    for (final row in first) {
      expect(row.animate, row.index < 8, reason: 'row ${row.index}');
    }
    await tester.pump(const Duration(seconds: 1));

    await tester.dragUntilVisible(
      find.text('Extra service 15'),
      find.byType(CustomScrollView),
      const Offset(0, -300),
    );
    await tester.pump();
    expect(entranceOf(tester, 'Extra service 15').animate, isFalse);
    expect(opacityOf(tester, 'Extra service 15'), 1);

    await tester.dragUntilVisible(
      find.text('ChatGPT Plus'),
      find.byType(CustomScrollView),
      const Offset(0, 300),
    );
    await tester.pump();
    expect(entranceOf(tester, 'ChatGPT Plus').animate, isFalse);
    expect(opacityOf(tester, 'ChatGPT Plus'), 1);
  });

  testWidgets('list updates do not animate new rows', (tester) async {
    await pumpScreen(tester);
    await tester.pump(const Duration(seconds: 1));

    await tester.runAsync(
      () => repository.upsert(
        subscriptionFixture(
          id: 'new',
          name: 'Brand new',
          nextBillingDate: CalendarDate(2026, 9, 20),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Brand new'), findsOneWidget);
    expect(entranceOf(tester, 'Brand new').animate, isFalse);
    expect(opacityOf(tester, 'Brand new'), 1);
  });

  testWidgets('rows appear at once with reduce motion', (tester) async {
    await pumpScreen(tester, reduceMotion: true);

    expect(opacityOf(tester, 'ChatGPT Plus'), 1);
    expect(opacityOf(tester, 'Notion Plus'), 1);

    await selectTab(tester, 'Trials 1');
    expect(opacityOf(tester, 'Disney Plus'), 1);
  });

  test('the cancel collapse uses the 260ms token', () {
    expect(SubscriptionRow.collapseDuration, Motion.collapse);
    expect(Motion.collapse, const Duration(milliseconds: 260));
  });

  testWidgets('the cancel collapse is instant with reduce motion', (
    tester,
  ) async {
    await pumpScreen(tester, reduceMotion: true);
    await tester.drag(find.text('Spotify Premium'), const Offset(-200, 0));
    await tester.pump();
    await tester.pump(settle);

    final size = tester
        .widget<SizeTransition>(
          find.ancestor(
            of: find.text('Spotify Premium'),
            matching: find.byType(SizeTransition),
          ),
        )
        .sizeFactor;
    expect(size.value, 1);
    await tester.tap(find.text('Cancelled'));
    await tester.pump();

    expect(size.value, 0);
    await tester.pump(settle);
    await tester.pump(settle);
  });

  testWidgets('scrolling rebuilds neither the top bar nor the tabs', (
    tester,
  ) async {
    await pumpScreen(tester, subscriptions: manySubscriptions());
    await tester.pump(const Duration(seconds: 1));

    final counter = RebuildCounter()..start();
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -600));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.drag(find.byType(CustomScrollView), const Offset(0, 400));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(counter.of(SubscriptionRow), greaterThan(0));
    expect(counter.of(AllSubscriptionsScreen), 0);
    expect(counter.of(SubscriptionsTopBar), 0);
    expect(counter.named('SegmentedTabs'), 0);
  });
}
