import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lapse/features/backup/domain/backup_codec.dart';
import 'package:lapse/features/backup/domain/backup_format_exception.dart';
import 'package:lapse/features/backup/presentation/backup_actions.dart';

import '../../../helpers/fake_subscription_repository.dart';
import '../../../helpers/fake_system_bridge.dart';
import '../../../helpers/in_memory_settings_repository.dart';
import '../../../helpers/pump_app.dart';
import '../../../helpers/subscription_fixtures.dart';
import '../backup_harness.dart';
import '../backup_test_data.dart';

void main() {
  late FakeSubscriptionRepository repository;
  late InMemorySettingsRepository settings;

  Future<FakeSystemBridge> pump(
    WidgetTester tester, [
    FakeSystemBridge? customBridge,
  ]) async {
    final bridge = customBridge ?? FakeSystemBridge();
    repository = FakeSubscriptionRepository()
      ..seed([subscriptionFixture(id: 'existing')]);
    settings = InMemorySettingsRepository(startingSettings());
    await tester.pumpLapse(
      ProviderScope(
        overrides: backupOverrides(
          repository: repository,
          bridge: bridge,
          settings: settings,
        ),
        child: Consumer(
          builder: (context, ref, _) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(
                onPressed: () => exportBackup(context, ref),
                child: const Text('Export'),
              ),
              TextButton(
                onPressed: () => importBackup(context, ref),
                child: const Text('Import'),
              ),
            ],
          ),
        ),
      ),
    );
    return bridge;
  }

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 150));
    }
  }

  List<int> validBytes() => utf8.encode(BackupCodec.encode(fullBackup()));

  group('export', () {
    testWidgets('shows Backup saved on success', (tester) async {
      final bridge = await pump(tester);

      await tester.tap(find.text('Export'));
      await settle(tester);

      expect(bridge.saved, hasLength(1));
      expect(find.text('Backup saved'), findsOneWidget);
    });

    testWidgets('does nothing when cancelled', (tester) async {
      final bridge = await pump(tester, FakeSystemBridge(saveSucceeds: false));

      await tester.tap(find.text('Export'));
      await settle(tester);

      expect(bridge.saved, isEmpty);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('reports a platform failure', (tester) async {
      await pump(tester, ThrowingSystemBridge());

      await tester.tap(find.text('Export'));
      await settle(tester);

      expect(find.text("Couldn't save the backup"), findsOneWidget);
    });
  });

  group('import', () {
    testWidgets('does nothing when the picker is cancelled', (tester) async {
      final bridge = await pump(tester);

      await tester.tap(find.text('Import'));
      await settle(tester);

      expect(bridge.documentsRequested, 1);
      expect(find.text('Import backup'), findsNothing);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('shows the reason for an invalid file', (tester) async {
      await pump(
        tester,
        FakeSystemBridge(documentToOpen: utf8.encode('{"app":"other"}')),
      );

      await tester.tap(find.text('Import'));
      await settle(tester);

      expect(
        find.text(const BackupFormatException.wrongApp().message),
        findsOneWidget,
      );
      expect(find.text('Import backup'), findsNothing);
      expect(repository.subscriptions.keys, ['existing']);
    });

    testWidgets('reports a file that cannot be opened', (tester) async {
      await pump(tester, ThrowingSystemBridge());

      await tester.tap(find.text('Import'));
      await settle(tester);

      expect(find.text("Couldn't open that file."), findsOneWidget);
    });

    testWidgets('closing the preview changes nothing', (tester) async {
      await pump(tester, FakeSystemBridge(documentToOpen: validBytes()));

      await tester.tap(find.text('Import'));
      await settle(tester);
      expect(find.text('5 subscriptions · 3 payments'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Close'));
      await settle(tester);

      expect(repository.subscriptions.keys, ['existing']);
      expect(settings.saveCount, 0);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('Replace all imports and confirms', (tester) async {
      await pump(tester, FakeSystemBridge(documentToOpen: validBytes()));

      await tester.tap(find.text('Import'));
      await settle(tester);
      final replace = find.widgetWithText(InkWell, 'Replace all');
      await tester.ensureVisible(replace);
      await tester.tap(replace);
      await settle(tester);

      expect(repository.subscriptions.keys, isNot(contains('existing')));
      expect(repository.subscriptions, hasLength(5));
      expect(settings.load().defaultCurrency, 'USD');
      expect(find.text('Imported 5 subscriptions'), findsOneWidget);
    });

    testWidgets('Merge keeps existing data and confirms', (tester) async {
      await pump(tester, FakeSystemBridge(documentToOpen: validBytes()));

      await tester.tap(find.text('Import'));
      await settle(tester);
      await tester.tap(find.widgetWithText(InkWell, 'Merge'));
      await settle(tester);

      expect(repository.subscriptions, hasLength(6));
      expect(find.text('Imported 5 subscriptions'), findsOneWidget);
    });
  });
}
