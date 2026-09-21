import 'package:flutter/material.dart';

import 'package:lapse/core/theme/theme.dart';
import 'package:lapse/core/widgets/widgets.dart';

enum DetailMenuAction { restore, delete }

Future<DetailMenuAction?> showDetailMenu(
  BuildContext context, {
  required String name,
  required bool isCancelled,
}) => showLapseSheet<DetailMenuAction>(
  context: context,
  title: name,
  builder: (_) => DetailMenu(isCancelled: isCancelled),
);

class DetailMenu extends StatelessWidget {
  const DetailMenu({required this.isCancelled, super.key});

  final bool isCancelled;

  @override
  Widget build(BuildContext context) {
    final c = context.lapse.colors;
    void choose(DetailMenuAction action) => Navigator.of(context).pop(action);

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        Space.md,
        0,
        Space.md,
        Space.lg + MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isCancelled)
            _MenuItem(
              icon: Icons.restore_rounded,
              label: 'Restore',
              color: c.ink,
              onTap: () => choose(DetailMenuAction.restore),
            ),
          _MenuItem(
            icon: Icons.delete_outline_rounded,
            label: 'Delete',
            color: c.dangerText,
            onTap: () => choose(DetailMenuAction.delete),
          ),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(Radii.control),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 52),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Space.md,
                vertical: Space.sm,
              ),
              child: Row(
                children: [
                  Icon(icon, size: 22, color: color),
                  const SizedBox(width: Space.md),
                  Expanded(
                    child: Text(
                      label,
                      style: context.lapse.text.itemTitle.copyWith(
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
