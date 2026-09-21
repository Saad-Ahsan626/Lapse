import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lapse/core/providers/clock_providers.dart';
import 'package:lapse/core/theme/theme.dart';
import 'package:lapse/core/widgets/widgets.dart';
import 'package:lapse/features/reminders/application/reminder_providers.dart';
import 'package:lapse/features/reminders/data/reminder_permission.dart';
import 'package:lapse/features/reminders/data/system_settings.dart';
import 'package:lapse/features/reminders/presentation/widgets/bell_illustration.dart';
import 'package:lapse/features/reminders/presentation/widgets/notification_preview_card.dart';
import 'package:lapse/features/settings/presentation/providers/settings_providers.dart';

class ReminderPermissionScreen extends ConsumerStatefulWidget {
  const ReminderPermissionScreen({super.key});

  static const title = 'One nudge is all it takes';
  static const body =
      'Lapse only notifies you about charges that are about to happen. '
      'No digests, no marketing, no daily noise.';
  static const deniedHint =
      'Notifications are turned off for Lapse. Turn them on in Settings.';
  static const grantedMessage = 'Reminders are on';
  static const snooze = Duration(days: 7);

  @override
  ConsumerState<ReminderPermissionScreen> createState() =>
      _ReminderPermissionScreenState();
}

class _ReminderPermissionScreenState
    extends ConsumerState<ReminderPermissionScreen>
    with WidgetsBindingObserver {
  bool _requesting = false;
  bool _acted = false;
  bool _denied = false;
  bool _closed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(ref.read(notificationPermissionProvider.notifier).refresh());
    }
  }

  Future<void> _allow() async {
    setState(() {
      _requesting = true;
      _acted = true;
    });
    var result = ReminderPermission.unknown;
    try {
      result = await ref
          .read(notificationPermissionProvider.notifier)
          .request();
    } finally {
      if (mounted) setState(() => _requesting = false);
    }
    if (!mounted) return;
    if (result == ReminderPermission.granted) {
      _finish(announce: true);
    } else {
      setState(() => _denied = true);
    }
  }

  void _openSettings() {
    setState(() => _acted = true);
    unawaited(openNotificationSettings());
  }

  Future<void> _later() async {
    final until = ref
        .read(clockProvider)()
        .toUtc()
        .add(
          ReminderPermissionScreen.snooze,
        );
    await ref
        .read(settingsProvider.notifier)
        .update(
          (settings) => settings.copyWith(remindersPromptSnoozedUntil: until),
        );
    if (mounted) _finish(announce: false);
  }

  void _finish({required bool announce}) {
    if (_closed) return;
    _closed = true;
    final messenger = ScaffoldMessenger.maybeOf(context);
    unawaited(Navigator.of(context).maybePop());
    if (announce) {
      messenger?.showSnackBar(
        const SnackBar(
          content: Text(ReminderPermissionScreen.grantedMessage),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(notificationPermissionProvider, (previous, next) {
      if (_acted &&
          !_requesting &&
          next.value == ReminderPermission.granted &&
          previous?.value != ReminderPermission.granted) {
        _finish(announce: true);
      }
    });
    final lapse = context.lapse;
    final permission = ref.watch(notificationPermissionProvider).value;
    final alreadyOn = !_acted && permission == ReminderPermission.granted;
    final showSettings =
        _denied || permission == ReminderPermission.permanentlyDenied;

    return Scaffold(
      backgroundColor: lapse.colors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  Space.screen,
                  Space.xxxl,
                  Space.screen,
                  Space.lg,
                ),
                child: Column(
                  children: [
                    const BellIllustration(),
                    const SizedBox(height: Space.xxxl + Space.sm),
                    Semantics(
                      header: true,
                      child: Text(
                        alreadyOn
                            ? 'Reminders are already on'
                            : ReminderPermissionScreen.title,
                        style: lapse.text.title.copyWith(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.8,
                          height: 1.15,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: Space.md),
                    Text(
                      alreadyOn
                          ? 'Lapse will nudge you before each charge. '
                                'You can change this in Settings any time.'
                          : ReminderPermissionScreen.body,
                      style: lapse.text.bodyMuted.copyWith(fontSize: 15),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: Space.xxl),
                    const NotificationPreviewCard(),
                    const Spacer(),
                    const SizedBox(height: Space.xxl),
                    ..._actions(
                      alreadyOn: alreadyOn,
                      showSettings: showSettings,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _actions({
    required bool alreadyOn,
    required bool showSettings,
  }) {
    final lapse = context.lapse;
    if (alreadyOn) {
      return [
        LapseButton(
          label: 'Done',
          expand: true,
          onPressed: () => _finish(announce: false),
        ),
      ];
    }
    return [
      if (showSettings) ...[
        Text(
          ReminderPermissionScreen.deniedHint,
          style: lapse.text.bodyMuted,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: Space.md),
      ],
      if (showSettings)
        LapseButton(
          label: 'Open settings',
          expand: true,
          icon: Icons.settings_outlined,
          onPressed: _openSettings,
        )
      else
        LapseButton(
          label: 'Allow notifications',
          expand: true,
          loading: _requesting,
          onPressed: () => unawaited(_allow()),
        ),
      const SizedBox(height: Space.sm),
      _QuietButton(
        label: 'Maybe later',
        onPressed: _requesting ? null : () => unawaited(_later()),
      ),
    ];
  }
}

class _QuietButton extends StatelessWidget {
  const _QuietButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final lapse = context.lapse;
    return Semantics(
      button: true,
      enabled: onPressed != null,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(Radii.control),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: Sizes.button,
            minWidth: double.infinity,
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: Space.lg),
              child: Text(
                label,
                style: lapse.text.button.copyWith(
                  color: lapse.colors.inkMuted,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
