import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lapse/features/subscriptions/presentation/form/subscription_form_args.dart';
import 'package:lapse/features/subscriptions/presentation/screens/add_edit_subscription_screen.dart';

import '../features/subscriptions/presentation/form_test_support.dart';
import '../helpers/fake_subscription_repository.dart';
import '../helpers/pump_app.dart';
import 'a11y_test_support.dart';

Future<void> pumpForm(
  WidgetTester tester,
  SubscriptionFormArgs args, {
  required Brightness brightness,
  required double textScale,
  FakeSubscriptionRepository? repository,
}) async {
  usePhone(tester);
  await tester.pumpLapse(
    AddEditSubscriptionScreen(args: args),
    wrapInScaffold: false,
    withProviders: true,
    brightness: brightness,
    textScale: textScale,
    overrides: formOverrides(
      repository ?? FakeSubscriptionRepository(),
      withSettings: false,
    ),
  );
  await frames(tester, 8);
}
