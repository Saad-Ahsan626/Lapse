import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lapse/core/theme/theme.dart';
import 'package:lapse/core/widgets/widgets.dart';
import 'package:lapse/features/catalog/domain/entities/catalog_service.dart';
import 'package:lapse/features/catalog/presentation/providers/catalog_providers.dart';

class CatalogServiceTile extends ConsumerWidget {
  const CatalogServiceTile({
    required this.service,
    this.size = Sizes.serviceTile,
    super.key,
  });

  final CatalogService service;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logos = ref.watch(logoAvailabilityProvider).value;
    final hasLogo = logos?.hasLogo(service.key) ?? false;
    return ServiceTile(
      name: service.name,
      initials: service.initials,
      brandColor: Color(service.brandColor),
      logoAsset: hasLogo ? service.logoAsset : null,
      size: size,
    );
  }
}
