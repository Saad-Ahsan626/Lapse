import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lapse/core/domain/calendar_date.dart';
import 'package:lapse/core/formatting/date_labels.dart';
import 'package:lapse/features/backup/domain/backup_data.dart';
import 'package:lapse/features/backup/domain/import_mode.dart';
import 'package:lapse/features/backup/presentation/widgets/import_preview_sheet.dart';

import '../../../../helpers/pump_app.dart';
import '../../../../helpers/subscription_fixtures.dart';
import '../../backup_test_data.dart';

void main() {
  late ImportMode? chosen;
  late bool closed;

  Future<void> open(
    WidgetTester tester,
    BackupData data, {
    double textScale = 1,
    Brightness brightness = Brightness.light,
  }) async {
    chosen = null;
    closed = false;
    await tester.pumpLapse(
      Builder(
        builder: (context) => TextButton(
          onPressed: () async {
            chosen = await showImportPreviewSheet(context, data);
            closed = true;
          },
          child: const Text('Open'),
        ),
      ),
      textScale: textScale,
      brightness: brightness,
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  testWidgets('shows counts, export date and both modes', (tester) async {
    await open(tester, fullBackup());

    expect(find.text('Import backup'), findsOneWidget);
    expect(find.text('5 subscriptions · 3 payments'), findsOneWidget);
    final exported = fullDateLabel(
      CalendarDate.fromDateTime(backupExportedAt.toLocal()),
    );
    expect(find.text('Exported $exported'), findsOneWidget);
    expect(find.text('Merge'), findsNWidgets(2));
    expect(find.text('Replace all'), findsNWidgets(2));
    expect(find.textContaining('most recently edited'), findsOneWidget);
    expect(find.textContaining('restores the backup exactly'), findsOneWidget);
  });

  testWidgets('uses singular labels for one of each', (tester) async {
    await open(
      tester,
      BackupData(
        exportedAt: backupExportedAt,
        settings: settingsFixture(),
        subscriptions: [subscriptionFixture()],
        charges: [chargeFixture('c', subscriptionId: 'sub-1')],
      ),
    );

    expect(find.text('1 subscription · 1 payment'), findsOneWidget);
  });

  testWidgets('Merge returns merge', (tester) async {
    await open(tester, fullBackup());

    await tester.tap(find.widgetWithText(InkWell, 'Merge'));
    await tester.pumpAndSettle();

    expect(closed, isTrue);
    expect(chosen, ImportMode.merge);
  });

  testWidgets('Replace all returns replace', (tester) async {
    await open(tester, fullBackup());

    await tester.ensureVisible(find.widgetWithText(InkWell, 'Replace all'));
    await tester.tap(find.widgetWithText(InkWell, 'Replace all'));
    await tester.pumpAndSettle();

    expect(chosen, ImportMode.replace);
  });

  testWidgets('closing returns nothing', (tester) async {
    await open(tester, fullBackup());

    await tester.tap(find.bySemanticsLabel('Close'));
    await tester.pumpAndSettle();

    expect(closed, isTrue);
    expect(chosen, isNull);
  });

  testWidgets('fits at text scale 2 in dark mode', (tester) async {
    await open(
      tester,
      fullBackup(),
      textScale: 2,
      brightness: Brightness.dark,
    );

    expect(tester.takeException(), isNull);
    expect(find.text('5 subscriptions · 3 payments'), findsOneWidget);
  });
}
