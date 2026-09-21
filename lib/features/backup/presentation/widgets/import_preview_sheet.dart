import 'package:flutter/material.dart';

import 'package:lapse/core/domain/calendar_date.dart';
import 'package:lapse/core/formatting/date_labels.dart';
import 'package:lapse/core/theme/theme.dart';
import 'package:lapse/core/widgets/widgets.dart';
import 'package:lapse/features/backup/domain/backup_data.dart';
import 'package:lapse/features/backup/domain/import_mode.dart';

Future<ImportMode?> showImportPreviewSheet(
  BuildContext context,
  BackupData data,
) => showLapseSheet<ImportMode>(
  context: context,
  title: 'Import backup',
  builder: (_) => ImportPreviewSheet(data: data),
);

String backupCountsLabel(BackupData data) {
  final subs = data.subscriptions.length;
  final payments = data.charges.length;
  return '$subs ${subs == 1 ? 'subscription' : 'subscriptions'} · '
      '$payments ${payments == 1 ? 'payment' : 'payments'}';
}

String backupExportedLabel(BackupData data) =>
    'Exported '
    '${fullDateLabel(CalendarDate.fromDateTime(data.exportedAt.toLocal()))}';

class ImportPreviewSheet extends StatelessWidget {
  const ImportPreviewSheet({required this.data, super.key});

  final BackupData data;

  @override
  Widget build(BuildContext context) {
    final lapse = context.lapse;
    void choose(ImportMode mode) => Navigator.of(context).pop(mode);

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        Space.screen,
        0,
        Space.screen,
        Space.xl + MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LapseCard(
            padding: const EdgeInsets.all(Space.lg),
            child: Row(
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  color: lapse.colors.primary,
                  size: 24,
                ),
                const SizedBox(width: Space.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        backupCountsLabel(data),
                        style: lapse.text.itemTitle,
                      ),
                      const SizedBox(height: Space.xs),
                      Text(
                        backupExportedLabel(data),
                        style: lapse.text.bodyMuted,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Space.xl),
          const _ModeExplanation(
            title: 'Merge',
            body:
                'Keeps what is on this phone and adds what is missing. '
                'When both have the same subscription, the most recently '
                'edited one wins.',
          ),
          const SizedBox(height: Space.md),
          const _ModeExplanation(
            title: 'Replace all',
            body:
                'Deletes every subscription and payment on this phone, '
                'then restores the backup exactly.',
          ),
          const SizedBox(height: Space.md),
          Text(
            'Either way, your settings from the backup are applied.',
            style: lapse.text.meta.copyWith(color: lapse.colors.inkMuted),
          ),
          const SizedBox(height: Space.xl),
          LapseButton(
            label: 'Merge',
            icon: Icons.merge_rounded,
            expand: true,
            onPressed: () => choose(ImportMode.merge),
          ),
          const SizedBox(height: 10),
          LapseButton(
            label: 'Replace all',
            icon: Icons.restore_rounded,
            variant: LapseButtonVariant.danger,
            expand: true,
            onPressed: () => choose(ImportMode.replace),
          ),
        ],
      ),
    );
  }
}

class _ModeExplanation extends StatelessWidget {
  const _ModeExplanation({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final lapse = context.lapse;
    return MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: lapse.text.itemTitle),
          const SizedBox(height: Space.xs),
          Text(body, style: lapse.text.bodyMuted),
        ],
      ),
    );
  }
}
