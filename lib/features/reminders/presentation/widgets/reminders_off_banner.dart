import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lapse/app/router/routes.dart';
import 'package:lapse/core/motion/motion.dart';
import 'package:lapse/core/providers/clock_providers.dart';
import 'package:lapse/core/theme/theme.dart';
import 'package:lapse/core/widgets/widgets.dart';
import 'package:lapse/features/reminders/application/reminder_providers.dart';
import 'package:lapse/features/reminders/data/reminder_permission.dart';
import 'package:lapse/features/settings/presentation/providers/settings_providers.dart';

class RemindersOffBanner extends ConsumerWidget {
  const RemindersOffBanner({this.padding = EdgeInsets.zero, super.key});

  static const String permissionRoute = Routes.remindersPermission;
  static const snooze = Duration(days: 7);

  final EdgeInsetsGeometry padding;

  static bool shouldShow({
    required ReminderPermission? permission,
    required DateTime? snoozedUntil,
    required DateTime now,
  }) {
    if (permission == null || permission == ReminderPermission.granted) {
      return false;
    }
    return snoozedUntil == null || !snoozedUntil.isAfter(now.toUtc());
  }

  Future<void> _dismiss(WidgetRef ref) {
    final until = ref.read(clockProvider)().toUtc().add(snooze);
    return ref
        .read(settingsProvider.notifier)
        .update(
          (settings) => settings.copyWith(remindersPromptSnoozedUntil: until),
        );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permission = ref.watch(notificationPermissionProvider).value;
    final snoozedUntil = ref.watch(
      settingsProvider.select((s) => s.remindersPromptSnoozedUntil),
    );
    final visible = shouldShow(
      permission: permission,
      snoozedUntil: snoozedUntil,
      now: ref.read(clockProvider)(),
    );

    return AnimatedSize(
      duration: reduceMotion(context) ? Duration.zero : Motion.expand,
      curve: Motion.emphasized,
      alignment: Alignment.topCenter,
      child: visible
          ? Padding(
              padding: padding,
              child: _BannerCard(
                onTurnOn: () => unawaited(context.push(permissionRoute)),
                onDismiss: () => unawaited(_dismiss(ref)),
              ),
            )
          : const SizedBox(width: double.infinity),
    );
  }
}

class _BannerCard extends StatelessWidget {
  const _BannerCard({required this.onTurnOn, required this.onDismiss});

  final VoidCallback onTurnOn;
  final VoidCallback onDismiss;

  static const double _badge = 40;

  @override
  Widget build(BuildContext context) {
    final lapse = context.lapse;
    final c = lapse.colors;
    final radius = BorderRadius.circular(Radii.card);

    return Semantics(
      container: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: radius,
          border: Border.all(color: c.border),
          boxShadow: c.cardShadow,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, Space.xs, Space.xs),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ExcludeSemantics(
                    child: Container(
                      width: _badge,
                      height: _badge,
                      decoration: BoxDecoration(
                        color: c.warningTint,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.notifications_off_outlined,
                        size: 20,
                        color: c.warningText,
                      ),
                    ),
                  ),
                  const SizedBox(width: Space.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Reminders are off',
                          style: lapse.text.itemTitle,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Turn them on so Lapse can warn you before a '
                          'charge.',
                          style: lapse.text.meta,
                        ),
                      ],
                    ),
                  ),
                  Semantics(
                    button: true,
                    label: 'Dismiss',
                    excludeSemantics: true,
                    child: InkResponse(
                      onTap: onDismiss,
                      radius: Sizes.minTap / 2,
                      child: SizedBox.square(
                        dimension: Sizes.minTap,
                        child: Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: c.inkSubtle,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: LapseButton(
                  label: 'Turn on',
                  variant: LapseButtonVariant.text,
                  onPressed: onTurnOn,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
