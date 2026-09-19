import 'package:flutter/material.dart';
import 'package:lapse/core/theme/theme.dart';
import 'package:lapse/core/widgets/widgets.dart';
import 'package:lapse/features/catalog/domain/entities/catalog_service.dart';
import 'package:lapse/features/catalog/presentation/widgets/catalog_service_tile.dart';

class CatalogServiceCard extends StatelessWidget {
  const CatalogServiceCard({
    required this.service,
    required this.onTap,
    super.key,
  });

  static const double minHeight = 112;
  static const EdgeInsets padding = EdgeInsets.symmetric(
    horizontal: 10,
    vertical: 14,
  );
  static const double gap = 9;

  final CatalogService service;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final lapse = context.lapse;
    return Semantics(
      button: true,
      label: service.name,
      excludeSemantics: true,
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: minHeight),
        child: LapseCard(
          padding: padding,
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CatalogServiceTile(service: service),
              const SizedBox(height: gap),
              Text(
                service.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: lapse.text.chip.copyWith(
                  fontWeight: FontWeight.w600,
                  color: lapse.colors.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
