import 'package:flutter/material.dart';

import 'package:lapse/core/theme/theme.dart';
import 'package:lapse/core/widgets/widgets.dart';
import 'package:lapse/features/settings/presentation/widgets/status_pill.dart';

class TroubleshootingRow extends StatelessWidget {
  const TroubleshootingRow({
    required this.icon,
    required this.title,
    required this.status,
    required this.tone,
    this.detail,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final IconData icon;
  final String title;
  final String status;
  final StatusTone tone;
  final String? detail;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final lapse = context.lapse;
    final c = lapse.colors;
    final note = detail;
    final action = actionLabel;
    final statusColor = switch (tone) {
      StatusTone.ok => c.savings,
      StatusTone.attention => c.warning,
      StatusTone.neutral => c.inkSubtle,
    };

    return Padding(
      padding: const EdgeInsets.all(Space.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          MergeSemantics(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ExcludeSemantics(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(icon, size: 22, color: statusColor),
                  ),
                ),
                const SizedBox(width: Space.md),
                Expanded(
                  child: Wrap(
                    spacing: Space.sm,
                    runSpacing: Space.xs,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(title, style: lapse.text.itemTitle),
                      StatusPill(label: status, tone: tone),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (note != null) ...[
            const SizedBox(height: Space.sm),
            Padding(
              padding: const EdgeInsets.only(left: 22 + Space.md),
              child: Text(note, style: lapse.text.bodyMuted),
            ),
          ],
          if (action != null) ...[
            const SizedBox(height: Space.md),
            Padding(
              padding: const EdgeInsets.only(left: 22 + Space.md),
              child: Align(
                alignment: Alignment.centerLeft,
                child: LapseButton(
                  label: action,
                  variant: LapseButtonVariant.secondary,
                  onPressed: onAction,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
