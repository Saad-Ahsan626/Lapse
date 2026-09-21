import 'dart:convert';

import 'package:flutter/services.dart';

import 'package:lapse/core/domain/calendar_date.dart';
import 'package:lapse/core/domain/clock.dart';
import 'package:lapse/core/platform/system_bridge.dart';
import 'package:lapse/features/backup/domain/backup_codec.dart';
import 'package:lapse/features/backup/domain/backup_data.dart';
import 'package:lapse/features/backup/domain/backup_format_exception.dart';
import 'package:lapse/features/backup/domain/backup_merge.dart';
import 'package:lapse/features/backup/domain/backup_settings.dart';
import 'package:lapse/features/backup/domain/import_mode.dart';
import 'package:lapse/features/backup/domain/import_result.dart';
import 'package:lapse/features/settings/domain/entities/app_settings.dart';
import 'package:lapse/features/subscriptions/domain/entities/charge.dart';
import 'package:lapse/features/subscriptions/domain/repositories/subscription_repository.dart';

typedef SettingsReader = AppSettings Function();

typedef SettingsWriter =
    Future<void> Function(AppSettings Function(AppSettings current) change);

typedef RollOver = Future<int> Function();

class BackupService {
  const BackupService({
    required SubscriptionRepository repository,
    required SystemBridge bridge,
    required Clock clock,
    required SettingsReader readSettings,
    required SettingsWriter updateSettings,
    required RollOver rollOver,
  }) : _repository = repository,
       _bridge = bridge,
       _clock = clock,
       _readSettings = readSettings,
       _updateSettings = updateSettings,
       _rollOver = rollOver;

  static const mimeType = 'application/json';

  final SubscriptionRepository _repository;
  final SystemBridge _bridge;
  final Clock _clock;
  final SettingsReader _readSettings;
  final SettingsWriter _updateSettings;
  final RollOver _rollOver;

  static String fileNameFor(DateTime localNow) =>
      'lapse-backup-${CalendarDate.fromDateTime(localNow).toIso()}.json';

  Future<BackupData> snapshot() async {
    final subscriptions = await _repository.getAll();
    return BackupData(
      exportedAt: _clock().toUtc(),
      settings: BackupSettings.of(_readSettings()),
      subscriptions: subscriptions,
      charges: await _allCharges(subscriptions.map((s) => s.id)),
    );
  }

  Future<bool> export() async {
    final data = await snapshot();
    return _bridge.saveDocument(
      fileName: fileNameFor(_clock()),
      mimeType: mimeType,
      bytes: utf8.encode(BackupCodec.encode(data)),
    );
  }

  Future<BackupData?> pickForImport() async {
    final List<int>? bytes;
    try {
      bytes = await _bridge.openDocument(mimeType: mimeType);
    } on PlatformException {
      throw const BackupFormatException.unreadable();
    }
    if (bytes == null) return null;
    final String text;
    try {
      text = utf8.decode(bytes);
    } on FormatException {
      throw const BackupFormatException.notJson();
    }
    return BackupCodec.decode(text);
  }

  Future<ImportResult> apply(BackupData data, ImportMode mode) async {
    switch (mode) {
      case ImportMode.replace:
        await _repository.replaceAll(data.subscriptions, data.charges);
      case ImportMode.merge:
        final local = await _repository.getAll();
        final merged = BackupMerge.merge(
          local: local,
          localCharges: await _allCharges(local.map((s) => s.id)),
          incoming: data.subscriptions,
          incomingCharges: data.charges,
        );
        await _repository.replaceAll(merged.subscriptions, merged.charges);
    }
    await _updateSettings(data.settings.applyTo);
    await _rollOver();
    return ImportResult(
      mode: mode,
      subscriptions: data.subscriptions.length,
      payments: data.charges.length,
    );
  }

  Future<List<Charge>> _allCharges(Iterable<String> subscriptionIds) async {
    final charges = <Charge>[];
    for (final id in subscriptionIds) {
      charges.addAll(await _repository.chargesFor(id));
    }
    return charges;
  }
}
