import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lapse/core/widgets/widgets.dart';
import 'package:lapse/features/subscriptions/presentation/form/subscription_form_args.dart';
import 'package:lapse/features/subscriptions/presentation/screens/add_edit_subscription_screen.dart';
import 'package:lapse/features/subscriptions/presentation/widgets/form/billing_cycle_section.dart';
import 'package:lapse/features/subscriptions/presentation/widgets/form/details_section.dart';
import 'package:lapse/features/subscriptions/presentation/widgets/form/form_header.dart';
import 'package:lapse/features/subscriptions/presentation/widgets/form/form_pop_scope.dart';
import 'package:lapse/features/subscriptions/presentation/widgets/form/form_save_bar.dart';
import 'package:lapse/features/subscriptions/presentation/widgets/form/next_billing_date_section.dart';
import 'package:lapse/features/subscriptions/presentation/widgets/form/price_section.dart';
import 'package:lapse/features/subscriptions/presentation/widgets/form/reminders_section.dart';
import 'package:lapse/features/subscriptions/presentation/widgets/form/trial_section.dart';

import '../../../../helpers/fake_subscription_repository.dart';
import '../../../../helpers/pump_app.dart';
import '../../../../helpers/rebuild_counter.dart';
import '../form_test_support.dart';

const List<Type> _sections = [
  TrialSection,
  PriceSection,
  BillingCycleSection,
  NextBillingDateSection,
  RemindersSection,
  DetailsSection,
];

void main() {
  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpLapse(
      const AddEditSubscriptionScreen(
        args: SubscriptionFormArgs(serviceKey: 'netflix'),
      ),
      wrapInScaffold: false,
      withProviders: true,
      overrides: formOverrides(
        FakeSubscriptionRepository(),
        withSettings: false,
      ),
    );
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  testWidgets('a keyboard inset change rebuilds only the save bar inset', (
    tester,
  ) async {
    await pumpScreen(tester);
    addTearDown(tester.view.resetViewInsets);

    final counter = RebuildCounter()..start();
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    await tester.pump();

    expect(counter.of(KeyboardInset), 1);
    expect(counter.of(AddEditSubscriptionScreen), 0);
    expect(counter.of(FormPopScope), 0);
    expect(counter.of(FormHeader), 0);
    expect(counter.of(FormSaveBar), 0);
    for (final section in _sections) {
      expect(counter.of(section), 0, reason: '$section');
    }
    final bar = tester.getRect(find.byType(FormSaveBar));
    expect(bar.bottom, closeTo(1800 - 300 / tester.view.devicePixelRatio, 0.5));
  });

  testWidgets('a keystroke in the name rebuilds only the name section', (
    tester,
  ) async {
    await pumpScreen(tester);
    final name = find.descendant(
      of: find.byType(FormHeader),
      matching: find.byType(TextField),
    );
    await tester.enterText(name, 'Netflix ');
    await tester.pump();

    final counter = RebuildCounter()..start();
    await tester.enterText(name, 'Netflix!');
    await tester.pump();

    expect(find.text('Netflix!'), findsOneWidget);
    expect(counter.of(FormHeader), 1);
    expect(counter.of(FormSaveBar), lessThanOrEqualTo(1));
    expect(counter.of(AddEditSubscriptionScreen), 0);
    expect(counter.of(FormPopScope), 0);
    expect(counter.of(KeyboardInset), 0);
    for (final section in _sections) {
      expect(counter.of(section), 0, reason: '$section');
    }
  });

  testWidgets('the first edit only flips the pop guard', (tester) async {
    await pumpScreen(tester);
    final price = find.descendant(
      of: find.byType(PriceSection),
      matching: find.byType(TextField),
    );

    final counter = RebuildCounter()..start();
    await tester.enterText(price, '649');
    await tester.pump();

    expect(counter.of(FormPopScope), 1);
    expect(counter.of(FormSaveBar), 1);
    expect(counter.of(AddEditSubscriptionScreen), 0);
    expect(counter.of(FormHeader), 0);
    expect(counter.of(PriceSection), 0);
    expect(counter.of(RemindersSection), 0);
    expect(counter.of(DetailsSection), 0);
    expect(
      tester
          .widget<LapseButton>(find.widgetWithText(LapseButton, 'Save'))
          .onPressed,
      isNotNull,
    );
  });
}
