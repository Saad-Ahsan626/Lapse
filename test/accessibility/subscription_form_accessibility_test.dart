import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lapse/features/subscriptions/presentation/form/subscription_form_args.dart';

import '../helpers/fake_subscription_repository.dart';
import '../helpers/subscription_fixtures.dart';
import 'a11y_form_support.dart';
import 'a11y_test_support.dart';

void main() {
  accessibilityTests('add subscription', (tester, brightness, scale) async {
    await pumpForm(
      tester,
      const SubscriptionFormArgs(serviceKey: 'netflix'),
      brightness: brightness,
      textScale: scale,
    );
  });

  accessibilityTests('add with trial on', (tester, brightness, scale) async {
    await pumpForm(
      tester,
      const SubscriptionFormArgs(serviceKey: 'netflix'),
      brightness: brightness,
      textScale: scale,
    );
    await tester.ensureVisible(find.byType(Switch));
    await tester.tap(find.byType(Switch));
    await frames(tester, 8);
  });

  accessibilityTests('edit subscription', (tester, brightness, scale) async {
    await pumpForm(
      tester,
      const SubscriptionFormArgs.edit('sub-1'),
      brightness: brightness,
      textScale: scale,
      repository: FakeSubscriptionRepository()..seed([subscriptionFixture()]),
    );
  });
}
