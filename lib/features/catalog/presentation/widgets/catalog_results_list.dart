import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lapse/app/router/routes.dart';
import 'package:lapse/core/theme/theme.dart';
import 'package:lapse/features/catalog/presentation/providers/catalog_providers.dart';
import 'package:lapse/features/catalog/presentation/widgets/catalog_add_tile.dart';
import 'package:lapse/features/catalog/presentation/widgets/catalog_result_row.dart';
import 'package:lapse/features/catalog/presentation/widgets/catalog_service_tile.dart';

class CatalogResultsList extends ConsumerWidget {
  const CatalogResultsList({
    required this.onSelect,
    this.padding = EdgeInsets.zero,
    super.key,
  });

  static const noResultsText = 'No service found';

  final ValueChanged<String> onSelect;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lapse = context.lapse;
    final query = ref.watch(catalogQueryProvider).trim();
    final results = ref.watch(catalogResultsProvider).value ?? const [];
    final lead = results.isEmpty ? 1 : 0;
    final count = results.length + lead + 1;

    return ListView.builder(
      padding: padding,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      itemCount: count,
      itemBuilder: (context, index) {
        if (results.isEmpty && index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: Space.md),
            child: Text(noResultsText, style: lapse.text.bodyMuted),
          );
        }
        if (index == count - 1) {
          final label = 'Add “$query” as custom';
          return CatalogResultRow(
            key: const ValueKey('catalog-add-custom'),
            leading: const CatalogAddTile(size: CatalogResultRow.tileSize),
            title: label,
            semanticLabel: label,
            accent: true,
            onTap: () => onSelect(Routes.newSubscriptionFor(name: query)),
          );
        }
        final service = results[index - lead];
        return Padding(
          padding: const EdgeInsets.only(bottom: Space.sm),
          child: CatalogResultRow(
            key: ValueKey('catalog-result-${service.key}'),
            leading: CatalogServiceTile(
              service: service,
              size: CatalogResultRow.tileSize,
            ),
            title: service.name,
            subtitle: service.category,
            semanticLabel: '${service.name}, ${service.category}',
            onTap: () =>
                onSelect(Routes.newSubscriptionFor(serviceKey: service.key)),
          ),
        );
      },
    );
  }
}
