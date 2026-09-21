import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lapse/features/backup/application/backup_service_provider.dart';
import 'package:lapse/features/backup/domain/backup_data.dart';
import 'package:lapse/features/backup/domain/backup_format_exception.dart';
import 'package:lapse/features/backup/domain/import_result.dart';
import 'package:lapse/features/backup/presentation/widgets/import_preview_sheet.dart';

const backupSavedMessage = 'Backup saved';
const backupSaveFailedMessage = "Couldn't save the backup";
const backupOpenFailedMessage = "Couldn't open that file.";
const backupImportFailedMessage = "Couldn't import the backup";

String importedMessage(ImportResult result) =>
    'Imported ${result.subscriptions} '
    '${result.subscriptions == 1 ? 'subscription' : 'subscriptions'}';

Future<void> exportBackup(BuildContext context, WidgetRef ref) async {
  final messenger = ScaffoldMessenger.of(context);
  final service = ref.read(backupServiceProvider);
  final bool saved;
  try {
    saved = await service.export();
  } on Object {
    _show(messenger, backupSaveFailedMessage);
    return;
  }
  if (saved) _show(messenger, backupSavedMessage);
}

Future<void> importBackup(BuildContext context, WidgetRef ref) async {
  final messenger = ScaffoldMessenger.of(context);
  final service = ref.read(backupServiceProvider);
  final BackupData? data;
  try {
    data = await service.pickForImport();
  } on BackupFormatException catch (error) {
    _show(messenger, error.message);
    return;
  } on Object {
    _show(messenger, backupOpenFailedMessage);
    return;
  }
  if (data == null || !context.mounted) return;
  final mode = await showImportPreviewSheet(context, data);
  if (mode == null) return;
  final ImportResult result;
  try {
    result = await service.apply(data, mode);
  } on Object {
    _show(messenger, backupImportFailedMessage);
    return;
  }
  _show(messenger, importedMessage(result));
}

void _show(ScaffoldMessengerState messenger, String message) => messenger
  ..hideCurrentSnackBar()
  ..showSnackBar(SnackBar(content: Text(message)));
