import 'package:flutter/material.dart';

import 'package:lapse/core/motion/motion.dart';
import 'package:lapse/core/theme/lapse_theme.dart';
import 'package:lapse/core/theme/tokens/lapse_spacing.dart';
import 'package:lapse/core/widgets/buttons/press_scale.dart';

enum LapseChipTone { primary, trial }

class LapseChip extends StatelessWidget {
  const LapseChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.showCheck = false,
    this.compact = false,
    this.tone = LapseChipTone.primary,
    this.onTint = false,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  final bool showCheck;
  final bool compact;
  final LapseChipTone tone;
  final bool onTint;

  @override
  Widget build(BuildContext context) {
    final lapse = context.lapse;
    final c = lapse.colors;
    final trial = tone == LapseChipTone.trial;
    final selectedBg = trial ? c.trialStrong : c.primary;
    final selectedFg = trial ? c.onTrial : c.onPrimary;
    final bg = selected
        ? selectedBg
        : onTint
        ? c.surface
        : c.surfaceMuted;
    final fg = selected ? selectedFg : c.onSurfaceMuted;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
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
              duration: Motion.chip,
              curve: Curves.easeOut,
              constraints: const BoxConstraints(minHeight: Sizes.chip),
              padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 15),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(Radii.chip),
                border: onTint
                    ? Border.all(
                        color: selected ? selectedBg : c.inputBorder,
                      )
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (showCheck && selected) ...[
                    Icon(
                      Icons.check_rounded,
                      size: compact ? 15 : 16,
                      color: fg,
                    ),
                    SizedBox(width: compact ? 5 : 6),
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
