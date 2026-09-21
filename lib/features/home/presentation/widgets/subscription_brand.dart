import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lapse/features/catalog/presentation/providers/catalog_providers.dart';
import 'package:lapse/features/subscriptions/domain/entities/subscription.dart';

@immutable
class SubscriptionBrand {
  const SubscriptionBrand({this.initials, this.brandColor, this.logoAsset});

  factory SubscriptionBrand.watch(WidgetRef ref, Subscription subscription) {
    final key = subscription.catalogKey;
    if (key == null) return const SubscriptionBrand();
    final service = ref.watch(catalogServiceByKeyProvider(key));
    if (service == null) return const SubscriptionBrand();
    final logos = ref.watch(logoAvailabilityProvider).value;
    final hasLogo = logos?.hasLogo(key) ?? false;
    return SubscriptionBrand(
      initials: service.initials,
      brandColor: Color(service.brandColor),
      logoAsset: hasLogo ? service.logoAsset : null,
    );
  }

  static String heroTagFor(Subscription subscription) =>
      'tile-${subscription.id}';

  final String? initials;
  final Color? brandColor;
  final String? logoAsset;
}
