import 'package:flutter/material.dart';

import 'package:lapse/core/theme/theme.dart';

class SettingsRow extends StatelessWidget {
  const SettingsRow({
    required this.title,
    this.value,
    this.trailing,
    this.onTap,
    this.semanticValue,
    this.showChevron = true,
    super.key,
  });

  final String title;
  final String? value;
  final Widget? trailing;
  final VoidCallback? onTap;
  final String? semanticValue;
  final bool showChevron;

  static const double minHeight = 54;

  @override
  Widget build(BuildContext context) {
    final lapse = context.lapse;
    final c = lapse.colors;
    final shown = value;
    final extra = trailing;
    final spoken = semanticValue ?? shown;
    final chevron = showChevron && onTap != null;

    return Semantics(
      container: true,
      button: onTap != null,
      label: spoken == null ? title : '$title, $spoken',
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: minHeight),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Space.lg,
                vertical: Space.md,
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final stacked =
                      MediaQuery.textScalerOf(context).scale(1) >= 1.6;
                  final valueText = shown == null
                      ? null
                      : Text(
                          shown,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: stacked ? TextAlign.start : TextAlign.end,
                          style: lapse.text.body.copyWith(
                            color: c.inkSubtle,
                            fontWeight: FontWeight.w500,
                          ),
                        );
                  final chevronIcon = chevron
                      ? Icon(
                          Icons.chevron_right_rounded,
                          size: 20,
                          color: c.inkSubtle,
                        )
                      : null;
                  final titleText = Text(title, style: lapse.text.itemTitle);
                  if (stacked) {
                    return Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              titleText,
                              ?valueText,
                              if (extra != null) ...[
                                const SizedBox(height: Space.xs),
                                extra,
                              ],
                            ],
                          ),
                        ),
                        if (chevronIcon != null) ...[
                          const SizedBox(width: Space.xs),
                          chevronIcon,
                        ],
                      ],
                    );
                  }
                  final maxTrailing = constraints.maxWidth * 0.45;
                  return Row(
                    children: [
                      Expanded(child: titleText),
                      if (valueText != null) ...[
                        const SizedBox(width: Space.md),
                        ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: maxTrailing),
                          child: valueText,
                        ),
                      ],
                      if (extra != null) ...[
                        const SizedBox(width: Space.md),
                        ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: maxTrailing),
                          child: extra,
                        ),
                      ],
                      if (chevronIcon != null) ...[
                        const SizedBox(width: Space.xs),
                        chevronIcon,
                      ],
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
