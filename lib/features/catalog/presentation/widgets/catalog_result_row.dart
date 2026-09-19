import 'package:flutter/material.dart';
import 'package:lapse/core/theme/theme.dart';
import 'package:lapse/core/widgets/widgets.dart';

class CatalogResultRow extends StatelessWidget {
  const CatalogResultRow({
    required this.leading,
    required this.title,
    required this.semanticLabel,
    required this.onTap,
    this.subtitle,
    this.accent = false,
    super.key,
  });

  static const double tileSize = 40;

  final Widget leading;
  final String title;
  final String? subtitle;
  final String semanticLabel;
  final VoidCallback onTap;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final lapse = context.lapse;
    return Semantics(
      button: true,
      label: semanticLabel,
      excludeSemantics: true,
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: Sizes.minTap),
        child: LapseCard(
          radius: Radii.md,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          onTap: onTap,
          child: Row(
            children: [
              leading,
              const SizedBox(width: Space.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: accent
                          ? lapse.text.itemTitle.copyWith(
                              color: lapse.colors.primary,
                            )
                          : lapse.text.itemTitle,
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: lapse.text.meta,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
