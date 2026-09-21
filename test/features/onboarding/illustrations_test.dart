import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lapse/features/onboarding/presentation/widgets/illustrations/cancel_illustration.dart';
import 'package:lapse/features/onboarding/presentation/widgets/illustrations/charge_illustration.dart';
import 'package:lapse/features/onboarding/presentation/widgets/illustrations/reminder_illustration.dart';
import 'package:lapse/features/settings/presentation/providers/settings_providers.dart';

import '../../helpers/pump_app.dart';

void main() {
  const all = Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      ChargeIllustration(),
      ReminderIllustration(),
      CancelIllustration(),
    ],
  );

  for (final brightness in Brightness.values) {
    testWidgets('all illustrations render in ${brightness.name}', (
      tester,
    ) async {
      tester.view
        ..physicalSize = const Size(390, 844)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpLapse(all, brightness: brightness, withProviders: true);
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);
      expect(find.text('Trial'), findsOneWidget);
      expect(find.text('Day 7'), findsOneWidget);
      expect(find.text('CHARGED'), findsOneWidget);
      expect(find.text('Rs 649'), findsOneWidget);
      expect(find.text('today, 4:02 AM'), findsOneWidget);
      expect(find.text('3 days left'), findsOneWidget);
      expect(find.text('Tomorrow'), findsOneWidget);
    });
  }

  testWidgets('charge card uses the default currency', (tester) async {
    await tester.pumpLapse(const ChargeIllustration(), withProviders: true);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(ChargeIllustration)),
    );
    await container
        .read(settingsProvider.notifier)
        .update((s) => s.copyWith(defaultCurrency: 'USD'));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text(r'$9.99'), findsOneWidget);
  });

  testWidgets('illustrations are hidden from semantics', (tester) async {
    final handle = tester.ensureSemantics();
    tester.view
      ..physicalSize = const Size(390, 844)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpLapse(all, withProviders: true);
    await tester.pump(const Duration(seconds: 1));
    expect(find.bySemanticsLabel('Lapse logo'), findsNothing);
    expect(find.bySemanticsLabel('Rs 649'), findsNothing);
    handle.dispose();
  });
}
