import 'package:flutter/material.dart';

import 'package:lapse/core/theme/theme.dart';
import 'package:lapse/core/widgets/widgets.dart';

class DetailActionsBar extends StatelessWidget {
  const DetailActionsBar({
    required this.isCancelled,
    required this.onCancelNow,
    required this.onMarkCancelled,
    required this.onRestore,
    required this.onDelete,
    super.key,
  });

  final bool isCancelled;
  final VoidCallback onCancelNow;
  final VoidCallback onMarkCancelled;
  final VoidCallback onRestore;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final c = context.lapse.colors;
    const gap = 10.0;

    final Widget lead = isCancelled
        ? LapseButton(
            label: 'Restore',
            icon: Icons.restore_rounded,
            expand: true,
            onPressed: onRestore,
          )
        : LapseButton(
            label: 'Mark as cancelled',
            variant: LapseButtonVariant.secondary,
            expand: true,
            onPressed: onMarkCancelled,
          );

    return ColoredBox(
      color: c.background,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            Space.xl,
            14,
            Space.xl,
            Space.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!isCancelled) ...[
                DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(Radii.control),
                    boxShadow: c.heroShadow,
                  ),
                  child: LapseButton(
                    label: 'Cancel now',
                    trailingIcon: Icons.north_east_rounded,
                    expand: true,
                    onPressed: onCancelNow,
                  ),
                ),
                const SizedBox(height: gap),
              ],
              Row(
                children: [
                  Expanded(child: lead),
                  const SizedBox(width: gap),
                  LapseButton(
                    label: 'Delete',
                    variant: LapseButtonVariant.danger,
                    onPressed: onDelete,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
