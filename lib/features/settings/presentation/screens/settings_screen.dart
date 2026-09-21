import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:lapse/app/router/routes.dart';
import 'package:lapse/core/theme/theme.dart';
import 'package:lapse/core/widgets/widgets.dart';
import 'package:lapse/features/backup/presentation/backup_actions.dart';
import 'package:lapse/features/settings/domain/entities/app_settings.dart';
import 'package:lapse/features/settings/presentation/formatting/settings_labels.dart';
import 'package:lapse/features/settings/presentation/providers/app_version_provider.dart';
import 'package:lapse/features/settings/presentation/providers/notification_health_provider.dart';
import 'package:lapse/features/settings/presentation/providers/settings_providers.dart';
import 'package:lapse/features/settings/presentation/widgets/default_reminders_sheet.dart';
import 'package:lapse/features/settings/presentation/widgets/name_sheet.dart';
import 'package:lapse/features/settings/presentation/widgets/notification_health_refresher.dart';
import 'package:lapse/features/settings/presentation/widgets/reminder_time_sheet.dart';
import 'package:lapse/features/settings/presentation/widgets/settings_group.dart';
import 'package:lapse/features/settings/presentation/widgets/settings_row.dart';
import 'package:lapse/features/settings/presentation/widgets/settings_top_bar.dart';
import 'package:lapse/features/settings/presentation/widgets/status_pill.dart';
import 'package:lapse/features/settings/presentation/widgets/theme_segmented_row.dart';
import 'package:lapse/features/subscriptions/presentation/providers/link_opener_provider.dart';
import 'package:lapse/features/subscriptions/presentation/widgets/currency_picker_sheet.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({this.showDeveloperTools = kDebugMode, super.key});

  final bool showDeveloperTools;

  static const appName = 'Lapse';
  static const currencyNote =
      'Used for new subscriptions and totals. Existing subscriptions keep '
      'their own currency.';
  static final Uri rateUri = Uri.parse(
    'market://details?id=io.github.saad_ahsan626.lapse',
  );
  static final Uri rateWebUri = Uri.parse(
    'https://play.google.com/store/apps/details?id=io.github.saad_ahsan626.lapse',
  );
  static final Uri sourceUri = Uri.parse(
    'https://github.com/Saad-Ahsan626/lapse',
  );
  static const linkFailedMessage = "Couldn't open the link";

  Future<void> _update(
    WidgetRef ref,
    AppSettings Function(AppSettings current) change,
  ) => ref.read(settingsProvider.notifier).update(change);

  Future<void> _editCurrency(BuildContext context, WidgetRef ref) async {
    final code = await showCurrencyPicker(
      context,
      ref.read(settingsProvider).defaultCurrency,
    );
    if (code == null) return;
    await _update(ref, (s) => s.copyWith(defaultCurrency: code));
  }

  Future<void> _editReminders(BuildContext context, WidgetRef ref) async {
    final offsets = await showDefaultRemindersSheet(
      context,
      ref.read(settingsProvider).defaultReminderOffsets,
    );
    if (offsets == null) return;
    await _update(ref, (s) => s.copyWith(defaultReminderOffsets: offsets));
  }

  Future<void> _editTime(BuildContext context, WidgetRef ref) async {
    final view = View.of(context);
    final direction = Directionality.of(context);
    final minutes = await showReminderTimeSheet(
      context,
      ref.read(settingsProvider).reminderMinutes,
    );
    if (minutes == null) return;
    await _update(ref, (s) => s.copyWith(reminderMinutes: minutes));
    await SemanticsService.sendAnnouncement(
      view,
      reminderTimeSavedMessage(minutes),
      direction,
    );
  }

  Future<void> _editName(BuildContext context, WidgetRef ref) async {
    final name = await showNameSheet(
      context,
      ref.read(settingsProvider).userName,
    );
    if (name == null) return;
    await _update(
      ref,
      (s) => s.copyWith(userName: name.isEmpty ? null : name),
    );
  }

  Future<void> _open(
    BuildContext context,
    WidgetRef ref,
    List<Uri> candidates,
  ) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final opener = ref.read(linkOpenerProvider);
    for (final uri in candidates) {
      try {
        if (await opener.open(uri)) return;
      } on Object {
        continue;
      }
    }
    messenger?.showSnackBar(
      const SnackBar(content: Text(linkFailedMessage)),
    );
  }

  void _licences(BuildContext context, WidgetRef ref) {
    showLicensePage(
      context: context,
      applicationName: appName,
      applicationVersion: ref.read(appVersionProvider).value?.label,
      applicationIcon: const Padding(
        padding: EdgeInsets.all(Space.sm),
        child: LogoMark(),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final health = ref.watch(notificationHealthProvider).value;
    final version = ref.watch(appVersionProvider).value;
    final name = settings.userName?.trim() ?? '';
    void run(Future<void> Function() action) => unawaited(action());

    return NotificationHealthRefresher(
      child: Scaffold(
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.only(bottom: Space.xxxl),
            children: [
              const SettingsTopBar(title: 'Settings'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Space.screen),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: Space.sm),
                    SettingsGroup(
                      label: 'Money',
                      footer: currencyNote,
                      children: [
                        SettingsRow(
                          title: 'Currency',
                          value: currencyLabel(settings.defaultCurrency),
                          onTap: () => run(() => _editCurrency(context, ref)),
                        ),
                      ],
                    ),
                    const SizedBox(height: Space.xxl),
                    SettingsGroup(
                      label: 'Reminders',
                      children: [
                        SettingsRow(
                          title: 'Default reminders',
                          value: reminderOffsetsLabel(
                            settings.defaultReminderOffsets,
                          ),
                          onTap: () => run(() => _editReminders(context, ref)),
                        ),
                        SettingsRow(
                          title: 'Reminder time',
                          value: reminderTimeLabel(settings.reminderMinutes),
                          onTap: () => run(() => _editTime(context, ref)),
                        ),
                        SettingsRow(
                          title: 'Notification troubleshooting',
                          showChevron: health == null,
                          semanticValue: health == null
                              ? null
                              : health.needsAttention
                              ? 'needs attention'
                              : 'all good',
                          trailing: health == null
                              ? null
                              : health.needsAttention
                              ? const StatusPill(
                                  label: 'Check',
                                  tone: StatusTone.attention,
                                )
                              : const StatusPill(
                                  label: 'OK',
                                  tone: StatusTone.ok,
                                ),
                          onTap: () => unawaited(
                            context.push<void>(
                              Routes.notificationTroubleshooting,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: Space.xxl),
                    SettingsGroup(
                      label: 'Appearance',
                      children: [
                        const ThemeSegmentedRow(),
                        SettingsRow(
                          title: 'Your name',
                          value: name.isEmpty ? 'Not set' : name,
                          onTap: () => run(() => _editName(context, ref)),
                        ),
                      ],
                    ),
                    const SizedBox(height: Space.xxl),
                    SettingsGroup(
                      label: 'Your data',
                      children: [
                        SettingsRow(
                          title: 'Export backup',
                          value: '.json',
                          semanticValue: 'JSON file',
                          onTap: () => run(() => exportBackup(context, ref)),
                        ),
                        SettingsRow(
                          title: 'Import backup',
                          onTap: () => run(() => importBackup(context, ref)),
                        ),
                      ],
                    ),
                    const SizedBox(height: Space.xxl),
                    SettingsGroup(
                      label: 'About',
                      children: [
                        SettingsRow(
                          title: 'Rate Lapse',
                          onTap: () => run(
                            () => _open(context, ref, [rateUri, rateWebUri]),
                          ),
                        ),
                        SettingsRow(
                          title: 'Source code',
                          value: 'GitHub',
                          onTap: () =>
                              run(() => _open(context, ref, [sourceUri])),
                        ),
                        SettingsRow(
                          title: 'Licences',
                          onTap: () => _licences(context, ref),
                        ),
                        SettingsRow(
                          title: 'Version',
                          value: version?.label ?? '…',
                        ),
                      ],
                    ),
                    if (showDeveloperTools) ...[
                      const SizedBox(height: Space.xxl),
                      SettingsGroup(
                        label: 'Developer',
                        children: [
                          SettingsRow(
                            title: 'Design gallery',
                            onTap: () =>
                                unawaited(context.push<void>(Routes.gallery)),
                          ),
                          SettingsRow(
                            title: 'Data inspector',
                            onTap: () => unawaited(
                              context.push<void>(Routes.dataInspector),
                            ),
                          ),
                          SettingsRow(
                            title: 'Replay splash',
                            onTap: () =>
                                unawaited(context.push<void>(Routes.splash)),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
