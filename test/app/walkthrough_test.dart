import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lapse/app/app.dart';
import 'package:lapse/app/router/app_router.dart';
import 'package:lapse/app/router/routes.dart';
import 'package:lapse/core/platform/system_bridge_provider.dart';
import 'package:lapse/core/providers/storage_providers.dart';
import 'package:lapse/features/reminders/data/reminder_permission.dart';
import 'package:lapse/features/savings/presentation/widgets/celebration_sheet.dart';
import 'package:lapse/features/settings/domain/entities/app_settings.dart';

import '../features/reminders/application/reminder_test_support.dart';
import '../helpers/fake_notification_gateway.dart';
import '../helpers/fake_system_bridge.dart';
import '../helpers/in_memory_settings_repository.dart';

Future<void> _frames(WidgetTester tester, [int count = 10]) async {
  for (var i = 0; i < count; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _tapText(
  WidgetTester tester,
  String text, {
  int frames = 10,
}) async {
  final finder = find.text(text);
  expect(finder, findsWidgets, reason: 'looking for "$text"');
  await tester.ensureVisible(finder.last);
  await tester.pump();
  await tester.tap(finder.last);
  await _frames(tester, frames);
}

void main() {
  testWidgets('first launch to cancel, backup and theme', (tester) async {
    tester.view
      ..physicalSize = const Size(390, 844)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final harness = ReminderHarness(
      gateway: FakeNotificationGateway(
        permissionResult: ReminderPermission.denied,
      ),
      settings: InMemorySettingsRepository(AppSettings(defaultCurrency: 'PKR')),
    );
    final bridge = FakeSystemBridge();
    final container = harness.container([
      initialLocationProvider.overrideWithValue(Routes.splash),
      deviceCountryProvider.overrideWithValue('PK'),
      systemBridgeProvider.overrideWithValue(bridge),
    ]);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const LapseApp()),
    );
    await _frames(tester, 85);
    expect(find.text('Free trials quietly turn into charges'), findsOneWidget);

    await _tapText(tester, 'Next');
    await _tapText(tester, 'Next');
    await _tapText(tester, 'Get started');
    expect(find.text('Set your defaults'), findsOneWidget);
    await _tapText(tester, 'Continue');
    await _tapText(tester, 'Allow notifications', frames: 15);
    expect(harness.settings.load().onboardingDone, isTrue);
    expect(find.text('Add your first subscription'), findsOneWidget);

    await _tapText(tester, 'Add your first subscription');
    await _tapText(tester, 'Netflix', frames: 12);
    await tester.tap(find.byType(Switch).first);
    await _frames(tester, 8);
    await tester.enterText(find.byType(TextField).at(1), '649');
    await _frames(tester, 3);
    await _tapText(tester, 'Save', frames: 15);

    final added = harness.repository.subscriptions.values.single;
    expect(added.name, 'Netflix');
    expect(added.isTrial, isTrue);
    expect(added.price.minor, 64900);
    await _frames(tester, 5);
    expect(
      harness.gateway.scheduled.values.map((entry) => entry.$1.title),
      contains('Netflix trial ends tomorrow'),
    );

    await _tapText(tester, 'Mark as cancelled', frames: 12);
    expect(find.byType(CelebrationSheet), findsOneWidget);
    expect(harness.repository.subscriptions.values.single.isCancelled, isTrue);
    await _tapText(tester, 'Undo', frames: 12);
    expect(harness.repository.subscriptions.values.single.isActive, isTrue);
    await _tapText(tester, 'Mark as cancelled', frames: 12);
    await _tapText(tester, 'Done', frames: 12);
    expect(harness.repository.subscriptions.values.single.isCancelled, isTrue);

    container.read(appRouterProvider).go(Routes.subscriptionsTab('cancelled'));
    await _frames(tester, 12);
    expect(find.text('Saved Rs 7,788 / year'), findsOneWidget);

    container.read(appRouterProvider).go(Routes.settings);
    await _frames(tester, 12);
    await _tapText(tester, 'Export backup', frames: 12);
    expect(bridge.saved, hasLength(1));
    bridge.documentToOpen = bridge.saved.single.bytes;
    await _tapText(tester, 'Import backup', frames: 12);
    await _tapText(tester, 'Merge', frames: 12);
    expect(harness.repository.subscriptions, hasLength(1));
    await _tapText(tester, 'Dark', frames: 12);
    expect(
      Theme.of(tester.element(find.text('Dark'))).brightness,
      Brightness.dark,
    );

    await tester.pumpWidget(const SizedBox());
    container.dispose();
    await tester.pump(const Duration(seconds: 2));
  });
}
