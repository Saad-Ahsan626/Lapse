import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lapse/core/providers/clock_providers.dart';
import 'package:lapse/core/theme/app_theme.dart';
import 'package:lapse/features/reminders/application/reminder_providers.dart';
import 'package:lapse/features/reminders/data/reminder_permission.dart';
import 'package:lapse/features/reminders/presentation/widgets/reminders_off_banner.dart';
import 'package:lapse/features/settings/domain/entities/app_settings.dart';
import 'package:lapse/features/settings/presentation/providers/settings_providers.dart';

import '../../../../helpers/fake_notification_gateway.dart';
import '../../../../helpers/in_memory_settings_repository.dart';

final _now = DateTime(2026, 9, 18, 19);

class _Harness {
  _Harness(this.settings, this.visited);

  final InMemorySettingsRepository settings;
  final List<String> visited;
}

Future<_Harness> _pump(
  WidgetTester tester, {
  ReminderPermission permission = ReminderPermission.denied,
  DateTime? snoozedUntil,
  Brightness brightness = Brightness.light,
  double textScale = 1,
}) async {
  final settings = InMemorySettingsRepository(
    AppSettings(
      defaultCurrency: 'PKR',
      remindersPromptSnoozedUntil: snoozedUntil,
    ),
  );
  final visited = <String>[];
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => const Scaffold(
          body: SingleChildScrollView(child: RemindersOffBanner()),
        ),
      ),
      GoRoute(
        path: '/reminders/permission',
        builder: (_, state) {
          visited.add(state.uri.toString());
          return const Scaffold(body: Text('Primer'));
        },
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        settingsRepositoryProvider.overrideWithValue(settings),
        notificationGatewayProvider.overrideWithValue(
          FakeNotificationGateway(permissionResult: permission),
        ),
        clockProvider.overrideWithValue(() => _now),
      ],
      child: MaterialApp.router(
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: brightness == Brightness.dark
            ? ThemeMode.dark
            : ThemeMode.light,
        routerConfig: router,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
      ),
    ),
  );
  await _settle(tester);
  return _Harness(settings, visited);
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  group('shouldShow', () {
    test('needs a known, non-granted permission and no active snooze', () {
      final now = DateTime.utc(2026, 9, 18, 12);
      expect(
        RemindersOffBanner.shouldShow(
          permission: null,
          snoozedUntil: null,
          now: now,
        ),
        isFalse,
      );
      expect(
        RemindersOffBanner.shouldShow(
          permission: ReminderPermission.granted,
          snoozedUntil: null,
          now: now,
        ),
        isFalse,
      );
      for (final permission in [
        ReminderPermission.denied,
        ReminderPermission.permanentlyDenied,
        ReminderPermission.unknown,
      ]) {
        expect(
          RemindersOffBanner.shouldShow(
            permission: permission,
            snoozedUntil: null,
            now: now,
          ),
          isTrue,
        );
      }
      expect(
        RemindersOffBanner.shouldShow(
          permission: ReminderPermission.denied,
          snoozedUntil: now.add(const Duration(minutes: 1)),
          now: now,
        ),
        isFalse,
      );
      expect(
        RemindersOffBanner.shouldShow(
          permission: ReminderPermission.denied,
          snoozedUntil: now.subtract(const Duration(minutes: 1)),
          now: now,
        ),
        isTrue,
      );
    });
  });

  testWidgets('shown when permission is denied', (tester) async {
    await _pump(tester);

    expect(find.text('Reminders are off'), findsOneWidget);
    expect(
      find.text('Turn them on so Lapse can warn you before a charge.'),
      findsOneWidget,
    );
    expect(find.text('Turn on'), findsOneWidget);
    expect(find.bySemanticsLabel('Dismiss'), findsOneWidget);
  });

  testWidgets('hidden when permission is granted', (tester) async {
    await _pump(tester, permission: ReminderPermission.granted);

    expect(find.text('Reminders are off'), findsNothing);
  });

  testWidgets('hidden while the snooze is active', (tester) async {
    await _pump(
      tester,
      snoozedUntil: _now.toUtc().add(const Duration(days: 2)),
    );

    expect(find.text('Reminders are off'), findsNothing);
  });

  testWidgets('shown again once the snooze has passed', (tester) async {
    await _pump(
      tester,
      snoozedUntil: _now.toUtc().subtract(const Duration(hours: 1)),
    );

    expect(find.text('Reminders are off'), findsOneWidget);
  });

  testWidgets('Turn on opens the permission primer', (tester) async {
    final harness = await _pump(tester);

    await tester.tap(find.text('Turn on'));
    await _settle(tester);

    expect(harness.visited, ['/reminders/permission']);
    expect(find.text('Primer'), findsOneWidget);
  });

  testWidgets('dismiss snoozes for 7 days and hides the banner', (
    tester,
  ) async {
    final harness = await _pump(tester);

    await tester.tap(find.bySemanticsLabel('Dismiss'));
    await _settle(tester);

    expect(
      harness.settings.load().remindersPromptSnoozedUntil,
      _now.toUtc().add(const Duration(days: 7)),
    );
    expect(find.text('Reminders are off'), findsNothing);
  });

  testWidgets('dismiss target is at least 44 logical pixels', (tester) async {
    await _pump(tester);

    final size = tester.getSize(
      find.ancestor(
        of: find.byIcon(Icons.close_rounded),
        matching: find.byType(InkResponse),
      ),
    );
    expect(size.width, greaterThanOrEqualTo(44));
    expect(size.height, greaterThanOrEqualTo(44));
  });

  for (final brightness in Brightness.values) {
    testWidgets('text scale 2 in ${brightness.name} does not overflow', (
      tester,
    ) async {
      await _pump(tester, brightness: brightness, textScale: 2);

      expect(tester.takeException(), isNull);
      expect(find.text('Reminders are off'), findsOneWidget);
    });
  }
}
