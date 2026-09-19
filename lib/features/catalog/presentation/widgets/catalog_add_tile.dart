import 'package:flutter/material.dart';
import 'package:lapse/core/theme/theme.dart';

class CatalogAddTile extends StatelessWidget {
  const CatalogAddTile({this.size = Sizes.serviceTile, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.lapse.colors;
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: c.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(Radii.tile(size)),
        ),
        child: Icon(Icons.add_rounded, size: size * 0.55, color: c.primary),
      ),
    );
  }
}
