import 'package:flutter/material.dart';
import 'package:lapse/core/domain/urgency.dart';
import 'package:lapse/core/theme/lapse_theme.dart';
import 'package:lapse/core/theme/tokens/lapse_spacing.dart';
import 'package:lapse/core/widgets/chips/trial_badge.dart';
import 'package:lapse/core/widgets/chips/urgency_chip.dart';
import 'package:lapse/core/widgets/layout/lapse_card.dart';
import 'package:lapse/core/widgets/subscription/service_tile.dart';

class SubscriptionListTile extends StatelessWidget {
  const SubscriptionListTile({
    required this.name,
    required this.meta,
    required this.dueLabel,
    required this.urgency,
    this.isTrial = false,
    this.initials,
    this.brandColor,
    this.logoAsset,
    this.heroTag,
    this.onTap,
    this.semanticState,
    this.semanticAmount,
    this.semanticWhen,
    super.key,
  });

  final String name;

  final String meta;

  final String dueLabel;
  final Urgency urgency;
  final bool isTrial;
  final String? initials;
  final Color? brandColor;
  final String? logoAsset;
  final Object? heroTag;
  final VoidCallback? onTap;
  final String? semanticState;
  final String? semanticAmount;
  final String? semanticWhen;

  static const chipWidthFactor = 0.48;
  static const largeTextChipWidthFactor = 0.42;

  static String semanticLabelFor({
    required String name,
    required String amount,
    required String when,
    String? state,
  }) => [
    name,
    ?state,
    amount,
    when,
  ].where((part) => part.isNotEmpty).join(', ');

  @override
  Widget build(BuildContext context) {
    final text = context.lapse.text;
    return Semantics(
      button: onTap != null,
      label: semanticLabelFor(
        name: name,
        state: semanticState ?? (isTrial ? 'free trial' : null),
        amount: semanticAmount ?? meta,
        when: semanticWhen ?? dueLabel,
      ),
      excludeSemantics: true,
      onTap: onTap,
      child: LapseCard(
        onTap: onTap,
        child: LayoutBuilder(
          builder: (context, constraints) => Row(
            children: [
              ServiceTile(
                name: name,
                initials: initials,
                brandColor: brandColor,
                logoAsset: logoAsset,
                heroTag: heroTag,
              ),
              const SizedBox(width: Space.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            style: text.itemTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isTrial) ...[
                          const SizedBox(width: Space.sm),
                          const TrialBadge(),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      meta,
                      style: text.meta,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: Space.sm),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth:
                      constraints.maxWidth *
                      (MediaQuery.textScalerOf(context).scale(1) > 1.2
                          ? largeTextChipWidthFactor
                          : chipWidthFactor),
                ),
                child: UrgencyChip(label: dueLabel, urgency: urgency),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
