import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lapse/features/backup/application/backup_service_provider.dart';
import 'package:lapse/features/backup/domain/backup_settings.dart';
import 'package:lapse/features/backup/domain/import_mode.dart';
import 'package:lapse/features/settings/presentation/providers/settings_providers.dart';
import 'package:lapse/features/subscriptions/data/repositories/subscription_repository_impl.dart';
import 'package:lapse/features/subscriptions/domain/entities/charge.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../helpers/fake_system_bridge.dart';
import '../../../helpers/in_memory_settings_repository.dart';
import '../../../helpers/subscription_fixtures.dart';
import '../../../helpers/test_database.dart';
import '../backup_harness.dart';
import '../backup_test_data.dart';

void main() {
  late Database db;
  late SubscriptionRepositoryImpl repository;
  late FakeSystemBridge bridge;
  late ProviderContainer container;

  setUp(() async {
    db = await openTestDatabase();
    repository = SubscriptionRepositoryImpl(db);
    bridge = FakeSystemBridge();
    container = backupContainer(
      repository: repository,
      bridge: bridge,
      settings: InMemorySettingsRepository(startingSettings()),
    );
  });

  tearDown(() async {
    container.dispose();
    await repository.dispose();
    await db.close();
  });

  Future<List<Charge>> allCharges() async => [
    for (final s in await repository.getAll())
      ...await repository.chargesFor(s.id),
  ];

  test('export, wipe, import (replace) gives identical data', () async {
    final backup = fullBackup();
    await repository.replaceAll(backup.subscriptions, backup.charges);
    await container
        .read(settingsProvider.notifier)
        .update(settingsFixture().applyTo);
    final subscriptionsBefore = await repository.getAll();
    final chargesBefore = await allCharges();
    final settingsBefore = container.read(settingsProvider);
    final service = container.read(backupServiceProvider);

    expect(await service.export(), isTrue);
    await repository.replaceAll(const [], const []);
    await container
        .read(settingsProvider.notifier)
        .update((_) => startingSettings());
    expect(await repository.getAll(), isEmpty);

    bridge.documentToOpen = bridge.saved.single.bytes;
    final picked = await service.pickForImport();
    await service.apply(picked!, ImportMode.replace);

    expect(await repository.getAll(), subscriptionsBefore);
    expect(await allCharges(), chargesBefore);
    expect(
      BackupSettings.of(container.read(settingsProvider)),
      BackupSettings.of(settingsBefore),
    );
  });

  test('merging the same backup twice does not duplicate', () async {
    final local = subscriptionFixture(id: 'local-only');
    await repository.replaceAll([local], const []);
    final service = container.read(backupServiceProvider);

    await service.apply(fullBackup(), ImportMode.merge);
    await service.apply(fullBackup(), ImportMode.merge);

    final all = await repository.getAll();
    expect(all, hasLength(6));
    expect(all.map((s) => s.id).toSet(), hasLength(6));
    expect(await allCharges(), hasLength(3));
  });
}
