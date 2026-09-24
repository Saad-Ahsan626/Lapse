import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lapse/core/domain/calendar_date.dart';
import 'package:lapse/features/backup/application/backup_service.dart';
import 'package:lapse/features/backup/application/backup_service_provider.dart';
import 'package:lapse/features/backup/domain/backup_codec.dart';
import 'package:lapse/features/backup/domain/backup_data.dart';
import 'package:lapse/features/backup/domain/backup_format_exception.dart';
import 'package:lapse/features/backup/domain/backup_settings.dart';
import 'package:lapse/features/backup/domain/import_mode.dart';
import 'package:lapse/features/backup/domain/import_result.dart';
import 'package:lapse/features/settings/domain/entities/app_theme_mode.dart';
import 'package:lapse/features/settings/presentation/providers/settings_providers.dart';
import 'package:lapse/features/subscriptions/domain/entities/charge.dart';

import '../../../helpers/fake_subscription_repository.dart';
import '../../../helpers/fake_system_bridge.dart';
import '../../../helpers/in_memory_settings_repository.dart';
import '../../../helpers/subscription_fixtures.dart';
import '../backup_harness.dart';
import '../backup_test_data.dart';

class _CountingRepository extends FakeSubscriptionRepository {
  int allChargesCalls = 0;
  int chargesForCalls = 0;

  @override
  Future<List<Charge>> allCharges() {
    allChargesCalls++;
    return super.allCharges();
  }

  @override
  Future<List<Charge>> chargesFor(String subscriptionId) {
    chargesForCalls++;
    return super.chargesFor(subscriptionId);
  }
}

void main() {
  late FakeSubscriptionRepository repository;
  late FakeSystemBridge bridge;
  late InMemorySettingsRepository settings;
  late ProviderContainer container;

  void start([FakeSystemBridge? customBridge]) {
    repository = FakeSubscriptionRepository();
    bridge = customBridge ?? FakeSystemBridge();
    settings = InMemorySettingsRepository(startingSettings());
    container = backupContainer(
      repository: repository,
      bridge: bridge,
      settings: settings,
    );
    addTearDown(container.dispose);
  }

  BackupService service() => container.read(backupServiceProvider);

  List<int> bytesOf(BackupData data) => utf8.encode(BackupCodec.encode(data));

  group('export', () {
    setUp(start);

    test('saves pretty JSON named after the local date', () async {
      final backup = fullBackup();
      repository
        ..seed(backup.subscriptions)
        ..charges.addAll(backup.charges);

      final saved = await service().export();

      expect(saved, isTrue);
      expect(bridge.saved, hasLength(1));
      final file = bridge.saved.single;
      expect(file.fileName, 'lapse-backup-2026-09-21.json');
      expect(file.mimeType, 'application/json');
      final decoded = BackupCodec.decode(utf8.decode(file.bytes));
      expect(decoded.exportedAt, backupNow.toUtc());
      expect(decoded.subscriptions, backup.subscriptions);
      expect(decoded.charges.toSet(), backup.charges.toSet());
      expect(
        decoded.settings,
        BackupSettings.of(startingSettings()),
      );
    });

    test('reads all charges in one query', () async {
      final counting = _CountingRepository();
      final backup = fullBackup();
      counting
        ..seed(backup.subscriptions)
        ..charges.addAll(backup.charges);
      final scoped = backupContainer(
        repository: counting,
        bridge: bridge,
        settings: settings,
      );
      addTearDown(scoped.dispose);

      final data = await scoped.read(backupServiceProvider).snapshot();

      expect(counting.allChargesCalls, 1);
      expect(counting.chargesForCalls, 0);
      expect(data.charges, await counting.allCharges());
    });

    test('returns false and records nothing when cancelled', () async {
      bridge.saveSucceeds = false;

      expect(await service().export(), isFalse);
      expect(bridge.saved, isEmpty);
    });

    test('file name uses the date passed in', () {
      expect(
        BackupService.fileNameFor(DateTime(2027, 1, 5, 0, 1)),
        'lapse-backup-2027-01-05.json',
      );
    });
  });

  group('pickForImport', () {
    test('returns null when the picker is cancelled', () async {
      start();

      expect(await service().pickForImport(), isNull);
      expect(bridge.documentsRequested, 1);
    });

    test('decodes a valid backup', () async {
      start();
      bridge.documentToOpen = bytesOf(fullBackup());

      expect(await service().pickForImport(), fullBackup());
    });

    test('rejects bytes that are not UTF-8 or not JSON', () async {
      start();
      bridge.documentToOpen = [0xff, 0xfe, 0x00];
      await expectLater(
        service().pickForImport(),
        throwsA(isA<BackupFormatException>()),
      );

      bridge.documentToOpen = utf8.encode('{"app":"other"}');
      await expectLater(
        service().pickForImport(),
        throwsA(
          isA<BackupFormatException>().having(
            (e) => e.message,
            'message',
            const BackupFormatException.wrongApp().message,
          ),
        ),
      );
    });

    test('turns a platform failure into a readable error', () async {
      start(ThrowingSystemBridge());

      await expectLater(
        service().pickForImport(),
        throwsA(
          isA<BackupFormatException>().having(
            (e) => e.message,
            'message',
            "Couldn't open that file.",
          ),
        ),
      );
    });
  });

  group('apply', () {
    setUp(start);

    test('replace swaps everything and applies the settings', () async {
      repository
        ..seed([subscriptionFixture(id: 'old')])
        ..charges.add(chargeFixture('old-charge', subscriptionId: 'old'));
      final backup = fullBackup();

      final result = await service().apply(backup, ImportMode.replace);

      expect(
        result,
        const ImportResult(
          mode: ImportMode.replace,
          subscriptions: 5,
          payments: 3,
        ),
      );
      expect(await repository.getAll(), backup.subscriptions);
      expect(repository.charges, backup.charges);
      final applied = container.read(settingsProvider);
      expect(applied.defaultCurrency, 'USD');
      expect(applied.reminderMinutes, 1230);
      expect(applied.defaultReminderOffsets, [3, 0]);
      expect(applied.themeMode, AppThemeMode.dark);
      expect(applied.userName, 'Saad');
      expect(applied.onboardingDone, isTrue);
      expect(
        applied.remindersPromptSnoozedUntil,
        startingSettings().remindersPromptSnoozedUntil,
      );
      expect(settings.load(), applied);
    });

    test('merge keeps newer records and does not duplicate', () async {
      final newerLocal = fullSubscription().copyWith(
        name: 'Edited here',
        updatedAt: DateTime.utc(2026, 9, 20),
      );
      final localOnly = subscriptionFixture(id: 'local-only');
      repository
        ..seed([newerLocal, localOnly])
        ..charges.add(chargeFixture('c-1', on: CalendarDate(2026, 7, 31)));
      final backup = fullBackup();

      await service().apply(backup, ImportMode.merge);
      await service().apply(backup, ImportMode.merge);

      final all = await repository.getAll();
      expect(all, hasLength(6));
      expect(all.firstWhere((s) => s.id == 'sub-full').name, 'Edited here');
      expect(all.map((s) => s.id), contains('local-only'));
      expect(repository.charges.map((c) => c.id).toList()..sort(), [
        'c-1',
        'c-2',
        'c-3',
      ]);
      expect(container.read(settingsProvider).themeMode, AppThemeMode.dark);
    });

    test('rolls imported past dates forward once', () async {
      final overdue = subscriptionFixture(
        id: 'overdue',
        nextBillingDate: CalendarDate(2026, 9, 1),
        startDate: CalendarDate(2026, 8, 1),
      );
      final backup = BackupData(
        exportedAt: backupExportedAt,
        settings: settingsFixture(),
        subscriptions: [overdue],
        charges: const [],
      );

      await service().apply(backup, ImportMode.replace);

      final rolled = await repository.getById('overdue');
      expect(rolled!.nextBillingDate, CalendarDate(2026, 10, 1));
      expect(repository.charges, hasLength(1));
    });

    test('a failing roll-over still reports the import', () async {
      final restored = settingsFixture();
      final backup = BackupData(
        exportedAt: backupExportedAt,
        settings: restored,
        subscriptions: [subscriptionFixture(id: 'kept')],
        charges: const [],
      );
      var rollOvers = 0;
      final failing = BackupService(
        repository: repository,
        bridge: bridge,
        clock: () => DateTime(2026, 9, 19, 10),
        readSettings: () => container.read(settingsProvider),
        updateSettings: (change) =>
            container.read(settingsProvider.notifier).update(change),
        rollOver: () {
          rollOvers++;
          return Future<int>.error(StateError('disk full'));
        },
      );

      final result = await failing.apply(backup, ImportMode.replace);

      expect(rollOvers, 1);
      expect(result.subscriptions, 1);
      expect((await repository.getAll()).map((s) => s.id), ['kept']);
      expect(container.read(settingsProvider).themeMode, restored.themeMode);
    });
  });
}
