import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lapse/app/router/routes.dart';
import 'package:lapse/features/backup/presentation/widgets/import_preview_sheet.dart';
import 'package:lapse/features/settings/domain/entities/app_settings.dart';
import 'package:lapse/features/settings/domain/entities/app_theme_mode.dart';

import '../features/backup/backup_test_data.dart';
import '../features/settings/presentation/settings_test_support.dart';
import '../helpers/pump_app.dart';
import 'a11y_test_support.dart';

SettingsHarness _harness(Brightness brightness) => SettingsHarness(
  settings: AppSettings(
    defaultCurrency: 'PKR',
    themeMode: brightness == Brightness.dark
        ? AppThemeMode.dark
        : AppThemeMode.light,
  ),
);

void main() {
  accessibilityTests('settings', (tester, brightness, scale) async {
    await _harness(brightness).pump(tester, textScale: scale);
  });

  accessibilityTests('troubleshooting', (tester, brightness, scale) async {
    await _harness(brightness).pump(
      tester,
      initialLocation: Routes.notificationTroubleshooting,
      textScale: scale,
    );
  });

  accessibilityTests('import preview sheet', (
    tester,
    brightness,
    scale,
  ) async {
    usePhone(tester);
    await tester.pumpLapse(
      Builder(
        builder: (context) => TextButton(
          onPressed: () => showImportPreviewSheet(context, fullBackup()),
          child: const Text('Open'),
        ),
      ),
      brightness: brightness,
      textScale: scale,
    );
    await tester.tap(find.text('Open'));
    await frames(tester, 8);
  });
}
