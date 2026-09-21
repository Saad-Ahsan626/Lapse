import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:lapse/core/domain/calendar_date.dart';
import 'package:lapse/core/theme/theme.dart';
import 'package:lapse/core/widgets/widgets.dart';
import 'package:lapse/features/catalog/presentation/providers/catalog_providers.dart';
import 'package:lapse/features/subscriptions/presentation/formatting/subscription_labels.dart';
import 'package:lapse/features/subscriptions/presentation/providers/subscription_detail.dart';

final _weekdayDate = DateFormat('EEE, d MMM', 'en_US');

String shortWeekdayDateLabel(CalendarDate date) =>
    _weekdayDate.format(date.toDateTime());

String detailHeroTag(String id) => 'tile-$id';

class DetailIdentity extends ConsumerWidget {
  const DetailIdentity({required this.detail, super.key});

  static const double tileSize = 64;

  final SubscriptionDetail detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lapse = context.lapse;
    final c = lapse.colors;
    final sub = detail.subscription;
    final key = sub.catalogKey;
    final service = key == null
        ? null
        : ref.watch(catalogServiceByKeyProvider(key));
    final hasLogo =
        key != null &&
        (ref.watch(logoAvailabilityProvider).value?.hasLogo(key) ?? false);

    final lineStyle = lapse.text.body.copyWith(
      fontSize: 15,
      fontWeight: FontWeight.w500,
      height: 1.35,
    );
    final category = sub.category ?? service?.category;
    final (String status, Color statusColor) = switch (detail.ringState) {
      DetailRingState.cancelled => (cancelledLabel(sub), c.inkMuted),
      DetailRingState.overdue => (
        'Was due ${shortWeekdayDateLabel(sub.nextBillingDate)}',
        c.urgencyChip(detail.urgency).foreground,
      ),
      _ => (
        '${sub.isTrial ? 'Trial ends' : 'Charges'} '
            '${shortWeekdayDateLabel(sub.nextBillingDate)}',
        c.urgencyChip(detail.urgency).foreground,
      ),
    };

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Radii.tile(tileSize)),
            boxShadow: c.cardShadow,
          ),
          child: ServiceTile(
            name: sub.name,
            initials: service?.initials,
            brandColor: service == null ? null : Color(service.brandColor),
            logoAsset: hasLogo ? service?.logoAsset : null,
            size: tileSize,
            heroTag: detailHeroTag(sub.id),
          ),
        ),
        const SizedBox(height: Space.lg),
        Semantics(
          header: true,
          child: Text(
            sub.name,
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: lapse.text.title.copyWith(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.8,
            ),
          ),
        ),
        const SizedBox(height: Space.xs),
        Text.rich(
          TextSpan(
            children: [
              if (category != null) ...[
                TextSpan(
                  text: category,
                  style: TextStyle(color: c.inkSubtle),
                ),
                TextSpan(
                  text: '  ·  ',
                  style: TextStyle(color: c.inkSubtle),
                ),
              ],
              TextSpan(
                text: status,
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          textAlign: TextAlign.center,
          style: lineStyle,
        ),
      ],
    );
  }
}
