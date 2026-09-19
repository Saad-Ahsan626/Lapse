import 'package:flutter/material.dart';

import 'package:lapse/core/theme/lapse_theme.dart';
import 'package:lapse/core/theme/tokens/lapse_spacing.dart';

class LapseSwitchRow extends StatelessWidget {
  const LapseSwitchRow({
    required this.label,
    required this.value,
    required this.onChanged,
    this.leading,
    this.activeColor,
    super.key,
  });

  final String label;
  final bool value;
  final ValueChanged<bool>? onChanged;

  final Widget? leading;

  final Color? activeColor;

  @override
  Widget build(BuildContext context) {
    final lapse = context.lapse;
    final c = lapse.colors;

    return MergeSemantics(
      child: Material(
        color: c.inputFill,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.control),
          side: BorderSide(color: c.inputBorder),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onChanged == null ? null : () => onChanged!(!value),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: Sizes.input),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  if (leading != null) ...[
                    leading!,
                    const SizedBox(width: 10),
                  ],
                  Expanded(child: Text(label, style: lapse.text.itemTitle)),
                  Switch(
                    value: value,
                    onChanged: onChanged,
                    activeTrackColor: activeColor ?? c.primary,
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
