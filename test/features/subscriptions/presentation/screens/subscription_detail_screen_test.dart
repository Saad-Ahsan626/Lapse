import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lapse/core/domain/calendar_date.dart';
import 'package:lapse/features/savings/presentation/widgets/celebration_sheet.dart';
import 'package:lapse/features/subscriptions/domain/entities/subscription.dart';
import 'package:lapse/features/subscriptions/domain/entities/subscription_status.dart';
import 'package:lapse/features/subscriptions/presentation/links/cancel_links.dart';
import 'package:lapse/features/subscriptions/presentation/screens/subscription_detail_screen.dart';
import 'package:lapse/features/subscriptions/presentation/widgets/detail/detail_ring.dart';

import '../../../../helpers/subscription_fixtures.dart';
import '../widgets/detail/detail_test_support.dart';

void main() {
  late DetailHarness harness;

  setUpAll(() => WidgetController.hitTestWarningShouldBeFatal = true);
  tearDownAll(() => WidgetController.hitTestWarningShouldBeFatal = false);

  setUp(() => harness = DetailHarness());

  Subscription chatGpt({
    int inDays = 3,
    bool isTrial = false,
    String? cancelUrl,
    SubscriptionStatus status = SubscriptionStatus.active,
  }) => subscriptionFixture(
    name: 'ChatGPT Plus',
    priceMinor: 560000,
    nextBillingDate: detailToday.addDays(inDays),
    startDate: CalendarDate(2025, 10, 21),
    isTrial: isTrial,
    cancelUrl: cancelUrl,
    status: status,
  ).copyWith(category: 'Productivity');

  Finder ringText(String text) =>
      find.descendant(of: find.byType(DetailRing), matching: find.text(text));

  group('ring', () {
    testWidgets('three days left', (tester) async {
      harness.repository.seed([chatGpt()]);
      await harness.pump(tester);

      expect(ringText('3'), findsOneWidget);
      expect(ringText('days left'), findsOneWidget);
      expect(find.textContaining('Charges Mon, 21 Sep'), findsOneWidget);
      expect(find.textContaining('Productivity'), findsOneWidget);
      expect(find.bySemanticsLabel('3 days left'), findsOneWidget);
    });

    testWidgets('one day left', (tester) async {
      harness.repository.seed([chatGpt(inDays: 1)]);
      await harness.pump(tester);

      expect(ringText('1'), findsOneWidget);
      expect(ringText('day left'), findsOneWidget);
    });

    testWidgets('due today', (tester) async {
      harness.repository.seed([chatGpt(inDays: 0)]);
      await harness.pump(tester);

      expect(ringText('Today'), findsOneWidget);
      expect(ringText('days left'), findsNothing);
    });

    testWidgets('overdue', (tester) async {
      harness.repository.seed([chatGpt(inDays: -2)]);
      await harness.pump(tester);

      expect(ringText('Due'), findsOneWidget);
      expect(find.textContaining('Was due Wed, 16 Sep'), findsOneWidget);
    });

    testWidgets('cancelled', (tester) async {
      harness.repository.seed([
        chatGpt(status: SubscriptionStatus.cancelled).copyWith(
          cancelledAt: DateTime(2026, 9, 12, 9),
        ),
      ]);
      await harness.pump(tester);

      expect(ringText('Cancelled'), findsOneWidget);
      expect(find.textContaining('Cancelled 12 Sep'), findsOneWidget);
      expect(find.text('Cancel now'), findsNothing);
      expect(find.text('Mark as cancelled'), findsNothing);
      expect(find.text('Restore'), findsOneWidget);
      expect(find.text('Next charge'), findsNothing);
    });

    testWidgets('trial', (tester) async {
      harness.repository.seed([chatGpt(inDays: 7, isTrial: true)]);
      await harness.pump(tester);

      expect(ringText('7'), findsOneWidget);
      expect(find.textContaining('Trial ends Fri, 25 Sep'), findsOneWidget);
      expect(find.text('First charge'), findsOneWidget);
      expect(find.text('Next charge'), findsNothing);
    });
  });

  group('info card', () {
    testWidgets('shows the design rows and hides unset ones', (tester) async {
      harness.repository.seed([chatGpt()]);
      await harness.pump(tester);

      expect(find.textContaining('Rs 5,600'), findsOneWidget);
      expect(find.textContaining('/month'), findsOneWidget);
      expect(find.text('Monthly'), findsOneWidget);
      expect(find.text('21 Sep 2026'), findsOneWidget);
      expect(find.text('Nothing yet'), findsOneWidget);
      expect(find.text('7 days and 1 day before'), findsOneWidget);
      expect(find.text('Tue, 21 Oct 2025'), findsOneWidget);
      expect(find.text('Payment method'), findsNothing);
      expect(find.text('Notes'), findsNothing);
      expect(find.text('Cancel link'), findsNothing);
    });

    testWidgets('shows payment, link, notes and total paid', (tester) async {
      final sub = chatGpt(
        cancelUrl: 'https://www.chatgpt.com/cancel/',
      ).copyWith(paymentMethod: 'HBL 4417', notes: 'Work account');
      harness.repository.seed([sub]);
      await harness.repository.applyRollOver(sub, [
        chargeFixture('a', CalendarDate(2026, 7, 21), minor: 560000),
        chargeFixture('b', CalendarDate(2026, 8, 21), minor: 560000),
      ]);
      await harness.pump(tester);

      expect(find.text('HBL 4417'), findsOneWidget);
      expect(find.text('Work account'), findsOneWidget);
      expect(find.text('chatgpt.com/cancel'), findsOneWidget);
      expect(find.text('Rs 11,200'), findsOneWidget);
    });

    testWidgets('tapping the cancel link opens it', (tester) async {
      harness.repository.seed([chatGpt(cancelUrl: 'chatgpt.com/cancel')]);
      await harness.pump(tester);

      await tester.drag(find.byType(ListView), const Offset(0, -600));
      await settle(tester);
      await tester.tap(find.text('chatgpt.com/cancel'));
      await settle(tester);

      expect(harness.opener.opened, [Uri.parse('https://chatgpt.com/cancel')]);
    });
  });

  group('cancel now', () {
    testWidgets('opens the cancel link', (tester) async {
      final sub = chatGpt(cancelUrl: 'https://chatgpt.com/cancel');
      harness.repository.seed([sub]);
      await harness.pump(tester);

      await tester.tap(find.text('Cancel now'));
      await settle(tester);

      expect(harness.opener.opened, [cancelUriFor(sub)]);
      expect(find.text('No cancel link yet'), findsNothing);
    });

    testWidgets('without a link, the sheet offers to add one', (
      tester,
    ) async {
      harness.repository.seed([chatGpt()]);
      await harness.pump(tester);

      await tester.tap(find.text('Cancel now'));
      await settle(tester);

      expect(harness.opener.opened, isEmpty);
      expect(find.text('No cancel link yet'), findsOneWidget);
      expect(
        find.text(
          "Add the service's cancel page so it's one tap away next time.",
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('Add a cancel link'));
      await settle(tester);

      expect(harness.location, '/subscription/sub-1/edit');
      expect(find.text('edit sub-1'), findsOneWidget);
    });

    testWidgets('without a link, the sheet searches how to cancel', (
      tester,
    ) async {
      harness.repository.seed([chatGpt()]);
      await harness.pump(tester);

      await tester.tap(find.text('Cancel now'));
      await settle(tester);
      await tester.tap(find.text('Search how to cancel'));
      await settle(tester);

      expect(harness.opener.opened, [howToCancelSearchUri('ChatGPT Plus')]);
      expect(find.text('No cancel link yet'), findsNothing);
    });

    testWidgets('a failed open falls back to the sheet', (tester) async {
      harness.opener.succeeds = false;
      harness.repository.seed([chatGpt(cancelUrl: 'https://chatgpt.com/x')]);
      await harness.pump(tester);

      await tester.tap(find.text('Cancel now'));
      await settle(tester);

      expect(harness.opener.opened, [Uri.parse('https://chatgpt.com/x')]);
      expect(find.text('No cancel link yet'), findsOneWidget);
    });
  });

  group('actions', () {
    testWidgets('mark as cancelled celebrates, Done keeps it cancelled', (
      tester,
    ) async {
      harness.repository.seed([chatGpt()]);
      await harness.pump(tester);

      await tester.tap(find.text('Mark as cancelled'));
      await settle(tester, frames: 20);

      expect(harness.repository.subscriptions['sub-1']!.isCancelled, isTrue);
      expect(find.byType(CelebrationSheet), findsOneWidget);
      expect(find.text('ChatGPT Plus cancelled'), findsOneWidget);
      expect(find.text('Rs 67,200'), findsOneWidget);
      expect(find.text('Nice move.'), findsOneWidget);

      await tester.tap(find.text('Done'));
      await settle(tester);

      expect(find.byType(CelebrationSheet), findsNothing);
      expect(harness.repository.subscriptions['sub-1']!.isCancelled, isTrue);
      expect(ringText('Cancelled'), findsOneWidget);
      expect(find.text('Restore'), findsOneWidget);
    });

    testWidgets('Undo on the celebration restores it', (tester) async {
      harness.repository.seed([chatGpt()]);
      await harness.pump(tester);

      await tester.tap(find.text('Mark as cancelled'));
      await settle(tester, frames: 20);
      await tester.tap(find.text('Undo'));
      await settle(tester);

      expect(find.byType(CelebrationSheet), findsNothing);
      expect(harness.repository.subscriptions['sub-1']!.isActive, isTrue);
      expect(find.text('ChatGPT Plus restored'), findsOneWidget);
      expect(find.text('Cancel now'), findsOneWidget);
    });

    testWidgets('restore brings it back', (tester) async {
      harness.repository.seed([
        chatGpt(status: SubscriptionStatus.cancelled),
      ]);
      await harness.pump(tester);

      await tester.tap(find.text('Restore'));
      await settle(tester);

      expect(harness.repository.subscriptions['sub-1']!.isCancelled, isFalse);
      expect(find.text('ChatGPT Plus restored'), findsOneWidget);
      expect(find.text('Cancel now'), findsOneWidget);
    });

    testWidgets('restore from the menu', (tester) async {
      harness.repository.seed([
        chatGpt(status: SubscriptionStatus.cancelled),
      ]);
      await harness.pump(tester);

      await tester.tap(find.bySemanticsLabel('More actions'));
      await settle(tester);
      expect(find.text('Delete'), findsNWidgets(2));
      await tester.tap(find.text('Restore').last);
      await settle(tester);

      expect(harness.repository.subscriptions['sub-1']!.isCancelled, isFalse);
    });

    testWidgets('delete asks, deletes and leaves', (tester) async {
      harness.repository.seed([chatGpt()]);
      await harness.pump(tester);

      await tester.tap(find.text('Delete'));
      await settle(tester);
      expect(find.text('Delete ChatGPT Plus?'), findsOneWidget);

      await tester.tap(find.text('Keep'));
      await settle(tester);
      expect(harness.repository.subscriptions, hasLength(1));
      expect(find.byType(SubscriptionDetailScreen), findsOneWidget);

      await tester.tap(find.text('Delete'));
      await settle(tester);
      await tester.tap(find.text('Delete').last);
      await settle(tester);

      expect(harness.repository.subscriptions, isEmpty);
      expect(find.byType(SubscriptionDetailScreen), findsNothing);
      expect(find.text('home'), findsOneWidget);
      expect(find.text('ChatGPT Plus deleted'), findsOneWidget);
      expect(find.text('This subscription was deleted'), findsNothing);
    });

    testWidgets('delete from the menu', (tester) async {
      harness.repository.seed([chatGpt()]);
      await harness.pump(tester);

      await tester.tap(find.bySemanticsLabel('More actions'));
      await settle(tester);
      expect(find.text('Restore'), findsNothing);
      await tester.tap(find.text('Delete').last);
      await settle(tester);
      await tester.tap(find.text('Delete').last);
      await settle(tester);

      expect(harness.repository.subscriptions, isEmpty);
      expect(find.text('home'), findsOneWidget);
    });

    testWidgets('edit pushes the edit route', (tester) async {
      harness.repository.seed([chatGpt()]);
      await harness.pump(tester);

      await tester.tap(find.text('Edit'));
      await settle(tester);

      expect(harness.location, '/subscription/sub-1/edit');
    });

    testWidgets('back pops', (tester) async {
      harness.repository.seed([chatGpt()]);
      await harness.pump(tester);

      await tester.tap(find.bySemanticsLabel('Back'));
      await settle(tester);

      expect(find.text('home'), findsOneWidget);
    });
  });

  group('missing', () {
    testWidgets('deleted while open pops back with a snackbar', (
      tester,
    ) async {
      harness.repository.seed([chatGpt()]);
      await harness.pump(tester);

      await harness.repository.delete('sub-1');
      await settle(tester);

      expect(find.byType(SubscriptionDetailScreen), findsNothing);
      expect(find.text('home'), findsOneWidget);
      expect(find.text('This subscription was deleted'), findsOneWidget);
    });

    testWidgets('not found without a back stack shows a message', (
      tester,
    ) async {
      await harness.pump(tester, id: 'ghost', pushed: false);

      expect(find.text('This subscription no longer exists'), findsOneWidget);

      await tester.tap(find.text('Go back'));
      await settle(tester);
      expect(find.text('home'), findsOneWidget);
    });
  });

  testWidgets('the big tile carries the hero tag', (tester) async {
    harness.repository.seed([chatGpt()]);
    await harness.pump(tester);

    expect(
      find.byWidgetPredicate((w) => w is Hero && w.tag == 'tile-sub-1'),
      findsOneWidget,
    );
  });

  for (final brightness in Brightness.values) {
    testWidgets('no overflow at text scale 2 (${brightness.name})', (
      tester,
    ) async {
      final sub =
          chatGpt(
            cancelUrl: 'https://www.chatgpt.com/account/manage/cancel',
          ).copyWith(
            paymentMethod: 'HBL Visa Platinum 4417',
            notes: 'Shared with the whole team, renew only if still used',
          );
      harness.repository.seed([sub]);
      await harness.pump(
        tester,
        brightness: brightness,
        textScale: 2,
        size: const Size(360, 780),
      );
      expect(tester.takeException(), isNull);

      await tester.drag(find.byType(ListView), const Offset(0, -2000));
      await settle(tester);
      expect(tester.takeException(), isNull);

      await tester.tap(find.bySemanticsLabel('More actions'));
      await settle(tester);
      expect(tester.takeException(), isNull);
    });
  }
}
