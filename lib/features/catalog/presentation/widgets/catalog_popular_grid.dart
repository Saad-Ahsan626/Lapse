import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lapse/app/router/routes.dart';
import 'package:lapse/features/catalog/presentation/providers/catalog_providers.dart';
import 'package:lapse/features/catalog/presentation/widgets/catalog_service_card.dart';
import 'package:lapse/features/catalog/presentation/widgets/custom_subscription_card.dart';

class CatalogPopularGrid extends ConsumerWidget {
  const CatalogPopularGrid({required this.onSelect, super.key});

  static const int columns = 3;
  static const double gap = 11;

  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final services = ref.watch(popularServicesProvider).value ?? const [];
    final cards = <Widget>[
      for (final service in services)
        CatalogServiceCard(
          key: ValueKey('catalog-card-${service.key}'),
          service: service,
          onTap: () =>
              onSelect(Routes.newSubscriptionFor(serviceKey: service.key)),
        ),
      CustomSubscriptionCard(
        key: const ValueKey('catalog-card-custom'),
        onTap: () => onSelect(Routes.newSubscription),
      ),
    ];
    final rows = <Widget>[];
    for (var start = 0; start < cards.length; start += columns) {
      if (rows.isNotEmpty) rows.add(const SizedBox(height: gap));
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = start; i < start + columns; i++) ...[
                if (i > start) const SizedBox(width: gap),
                Expanded(
                  child: i < cards.length ? cards[i] : const SizedBox.shrink(),
                ),
              ],
            ],
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: rows,
    );
  }
}
