import 'package:flutter/material.dart';
import 'package:lapse/core/theme/theme.dart';
import 'package:lapse/core/widgets/widgets.dart';
import 'package:lapse/features/catalog/presentation/widgets/catalog_add_tile.dart';
import 'package:lapse/features/catalog/presentation/widgets/catalog_service_card.dart';
import 'package:lapse/features/catalog/presentation/widgets/dashed_border_painter.dart';

class CustomSubscriptionCard extends StatelessWidget {
  const CustomSubscriptionCard({required this.onTap, super.key});

  static const label = 'Custom subscription';

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final lapse = context.lapse;
    final c = lapse.colors;
    final radius = BorderRadius.circular(Radii.card);
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: CatalogServiceCard.minHeight,
        ),
        child: PressScale(
          child: CustomPaint(
            foregroundPainter: DashedBorderPainter(
              color: c.primary.withValues(alpha: 0.4),
              radius: Radii.card,
            ),
            child: Material(
              color: c.primary.withValues(alpha: 0.07),
              borderRadius: radius,
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onTap,
                child: Padding(
                  padding: CatalogServiceCard.padding,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CatalogAddTile(),
                      const SizedBox(height: CatalogServiceCard.gap),
                      Text(
                        label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: lapse.text.chip.copyWith(
                          fontWeight: FontWeight.w600,
                          color: c.primary,
                        ),
                      ),
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
