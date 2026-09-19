import 'package:flutter/material.dart';

import 'package:lapse/core/theme/lapse_theme.dart';
import 'package:lapse/core/theme/tokens/lapse_spacing.dart';
import 'package:lapse/core/widgets/buttons/press_scale.dart';

class LapseChip extends StatelessWidget {
  const LapseChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.showCheck = false,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  final bool showCheck;

  @override
  Widget build(BuildContext context) {
    final lapse = context.lapse;
    final c = lapse.colors;
    final bg = selected ? c.primary : c.surfaceMuted;
    final fg = selected ? c.onPrimary : c.onSurfaceMuted;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: (Sizes.minTap - Sizes.chip) / 2,
          ),
          child: PressScale(
            enabled: onTap != null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              constraints: const BoxConstraints(minHeight: Sizes.chip),
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(Radii.chip),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (showCheck && selected) ...[
                    Icon(Icons.check_rounded, size: 16, color: fg),
                    const SizedBox(width: 6),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: lapse.text.chip.copyWith(
                        color: fg,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w600,
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
