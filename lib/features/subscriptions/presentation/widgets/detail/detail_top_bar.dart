import 'package:flutter/material.dart';

import 'package:lapse/core/theme/theme.dart';
import 'package:lapse/core/widgets/widgets.dart';

class DetailTopBar extends StatelessWidget {
  const DetailTopBar({
    required this.onBack,
    this.onEdit,
    this.onMenu,
    super.key,
  });

  final VoidCallback onBack;
  final VoidCallback? onEdit;
  final VoidCallback? onMenu;

  @override
  Widget build(BuildContext context) {
    final c = context.lapse.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.xs, Space.sm, Space.xs, 0),
      child: Row(
        children: [
          _SquareTap(
            label: 'Back',
            onTap: onBack,
            child: Icon(Icons.chevron_left_rounded, size: 30, color: c.ink),
          ),
          const Spacer(),
          if (onEdit != null)
            LapseButton(
              label: 'Edit',
              variant: LapseButtonVariant.text,
              onPressed: onEdit,
            ),
          if (onMenu != null)
            _SquareTap(
              label: 'More actions',
              onTap: onMenu!,
              child: Icon(Icons.more_vert_rounded, size: 24, color: c.ink),
            ),
        ],
      ),
    );
  }
}

class _SquareTap extends StatelessWidget {
  const _SquareTap({
    required this.label,
    required this.onTap,
    required this.child,
  });

  final String label;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: Tooltip(
        message: label,
        excludeFromSemantics: true,
        child: InkResponse(
          onTap: onTap,
          radius: Sizes.minTap / 2,
          child: SizedBox.square(
            dimension: Sizes.minTap,
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}
