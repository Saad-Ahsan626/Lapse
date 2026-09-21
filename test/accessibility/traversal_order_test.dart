import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lapse/core/domain/calendar_date.dart';
import 'package:lapse/features/subscriptions/presentation/form/subscription_form_args.dart';

import '../features/home/home_harness.dart';
import '../features/subscriptions/presentation/widgets/detail/detail_test_support.dart';
import '../helpers/subscription_fixtures.dart';
import 'a11y_data.dart';
import 'a11y_form_support.dart';

List<String> traversalLabels(WidgetTester tester) {
  var root = tester.getSemantics(find.byType(Scaffold).last);
  while (root.parent != null) {
    root = root.parent!;
  }
  final labels = <String>[];
  void visit(SemanticsNode node) {
    if (node.label.isNotEmpty) labels.add(node.label);
    node
        .debugListChildrenInOrder(DebugSemanticsDumpOrder.traversalOrder)
        .forEach(visit);
  }

  visit(root);
  return labels;
}

void expectInOrder(List<String> labels, List<String> expected) {
  var from = 0;
  for (final wanted in expected) {
    final index = labels.indexWhere((l) => l.contains(wanted), from);
    expect(index, isNot(-1), reason: '"$wanted" after $from in $labels');
    from = index + 1;
  }
}

void main() {
  testWidgets('Home reads header, hero, sections, then the FAB', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpHome(tester, subscriptions: homeSubscriptions());

    final labels = traversalLabels(tester);
    expectInOrder(labels, [
      'Good evening',
      'Settings',
      'This month, Rs 6,548',
      'Rs 78,966 per year',
      'Trials ending soon',
      'Netflix, free trial, Rs 649 monthly, charges tomorrow',
      'Upcoming charges',
      'ChatGPT Plus, Rs 5,600 monthly, charges tomorrow',
    ]);
    expect(labels.last, 'Add subscription');
    handle.dispose();
  });

  testWidgets('Detail reads top bar, ring, identity, info, then actions', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final harness = DetailHarness();
    harness.repository.seed([
      subscriptionFixture(
        name: 'ChatGPT Plus',
        nextBillingDate: CalendarDate(2026, 9, 21),
        cancelUrl: 'https://chatgpt.com/cancel',
      ),
    ]);
    await harness.pump(tester, size: const Size(390, 844));

    final labels = traversalLabels(tester);
    expectInOrder(labels, [
      'Back',
      'More actions',
      '3 days left',
      'Charges Mon, 21 Sep',
      'Price',
      'Cancel now',
      'Mark as cancelled',
      'Delete',
    ]);
    expect(labels.last, 'Delete');
    handle.dispose();
  });

  testWidgets('Add reads header, fields, then Save last', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpForm(
      tester,
      const SubscriptionFormArgs(serviceKey: 'netflix'),
      brightness: Brightness.light,
      textScale: 1,
    );

    final labels = traversalLabels(tester);
    expectInOrder(labels, [
      'Back',
      'Name',
      'Free trial',
      'Price in Pakistani rupee',
      'Monthly',
      'Next billing date',
      'Cancel link',
      'Notes',
      'Save',
    ]);
    expect(labels.last, 'Save');
    handle.dispose();
  });
}
