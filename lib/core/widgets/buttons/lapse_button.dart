import 'package:flutter/material.dart';

import 'package:lapse/core/theme/lapse_theme.dart';
import 'package:lapse/core/theme/tokens/lapse_spacing.dart';
import 'package:lapse/core/widgets/buttons/press_scale.dart';

enum LapseButtonVariant {
  primary,

  secondary,

  text,

  danger,
}

class LapseButton extends StatelessWidget {
  const LapseButton({
    required this.label,
    required this.onPressed,
    this.variant = LapseButtonVariant.primary,
    this.icon,
    this.trailingIcon,
    this.expand = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final LapseButtonVariant variant;
  final IconData? icon;
  final IconData? trailingIcon;

  final bool expand;

  @override
  Widget build(BuildContext context) {
    final c = context.lapse.colors;
    final enabled = onPressed != null;

    final (Color bg, Color fg, BorderSide side) = switch (variant) {
      LapseButtonVariant.primary => (c.primary, c.onPrimary, BorderSide.none),
      LapseButtonVariant.secondary => (
        c.surface,
        c.ink,
        BorderSide(color: c.borderStrong),
      ),
      LapseButtonVariant.text => (
        Colors.transparent,
        c.primary,
        BorderSide.none,
      ),
      LapseButtonVariant.danger => (
        c.dangerTint,
        c.dangerText,
        BorderSide.none,
      ),
    };
    final hPad = variant == LapseButtonVariant.text ? 18.0 : 22.0;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(Radii.control),
      side: side,
    );

    return Semantics(
      button: true,
      enabled: enabled,
      child: PressScale(
        enabled: enabled,
        child: AnimatedOpacity(
          opacity: enabled ? 1 : 0.4,
          duration: const Duration(milliseconds: 150),
          child: Material(
            color: bg,
            shape: shape,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onPressed,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: Sizes.button),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: hPad),
                  child: Row(
                    mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, size: 18, color: fg),
                        const SizedBox(width: Space.sm),
                      ],
                      Flexible(
                        child: Text(
                          label,
                          style: context.lapse.text.button.copyWith(color: fg),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (trailingIcon != null) ...[
                        const SizedBox(width: 6),
                        Icon(trailingIcon, size: 18, color: fg),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
