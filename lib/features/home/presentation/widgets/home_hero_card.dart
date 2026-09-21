import 'package:flutter/material.dart';
import 'package:lapse/core/domain/money.dart';
import 'package:lapse/core/formatting/money_formatter.dart';
import 'package:lapse/core/theme/theme.dart';
import 'package:lapse/core/widgets/widgets.dart';
import 'package:lapse/features/subscriptions/domain/services/spending_summary.dart';

class HomeHeroCard extends StatelessWidget {
  const HomeHeroCard({required this.summary, super.key});

  final SpendingSummary summary;

  static const double circleSize = 180;

  static String otherCurrenciesLabel(Map<String, Money> others) {
    final codes = others.keys.toList()..sort();
    final parts = codes.map((code) => '${formatMoney(others[code]!)}/yr');
    return '+ ${parts.join(' · ')} in other currencies';
  }

  @override
  Widget build(BuildContext context) {
    final lapse = context.lapse;
    final c = lapse.colors;
    final text = lapse.text;
    final radius = BorderRadius.circular(Radii.hero);
    final currency = summary.thisMonth.currency;
    const white = Colors.white;
    final yearlyAmount = formatMoney(summary.yearly);
    final yearly = '$yearlyAmount / year';
    final monthly = formatMoney(summary.thisMonth);

    return DecoratedBox(
      decoration: BoxDecoration(borderRadius: radius, boxShadow: c.heroShadow),
      child: ClipRRect(
        borderRadius: radius,
        child: DecoratedBox(
          decoration: BoxDecoration(gradient: c.heroGradient),
          child: Stack(
            children: [
              Positioned(
                top: -circleSize * 0.38,
                right: -circleSize * 0.3,
                child: ExcludeSemantics(
                  child: Container(
                    width: circleSize,
                    height: circleSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(Space.screen),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Semantics(
                      container: true,
                      label: 'This month, $monthly',
                      excludeSemantics: true,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'This month',
                            style: text.meta.copyWith(
                              color: white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: CountUpText(
                              value: summary.thisMonth.minor,
                              format: (v) => formatMoney(Money(v, currency)),
                              style: text.moneyHero.copyWith(color: white),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: Space.lg),
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: Space.md,
                      runSpacing: Space.sm,
                      children: [
                        Semantics(
                          label: '$yearlyAmount per year',
                          excludeSemantics: true,
                          child: Text(
                            yearly,
                            style: text.meta.copyWith(
                              color: white,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        if (summary.hasSavings)
                          _SavedPill(amount: summary.savedPerYear),
                      ],
                    ),
                    if (summary.otherCurrencies.isNotEmpty) ...[
                      const SizedBox(height: Space.sm),
                      Text(
                        otherCurrenciesLabel(summary.otherCurrencies),
                        style: text.meta.copyWith(color: white),
                      ),
                    ],
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

class _SavedPill extends StatelessWidget {
  const _SavedPill({required this.amount});

  final Money amount;

  @override
  Widget build(BuildContext context) {
    final lapse = context.lapse;
    final saved = formatMoney(amount);
    return Semantics(
      label: 'Saved $saved per year',
      excludeSemantics: true,
      child: Container(
        constraints: const BoxConstraints(minHeight: Sizes.chipSmall),
        padding: const EdgeInsets.symmetric(horizontal: Space.md, vertical: 6),
        decoration: BoxDecoration(
          color: lapse.colors.savings,
          borderRadius: BorderRadius.circular(Radii.pill),
        ),
        child: Text(
          'Saved $saved 🎉',
          style: lapse.text.chip.copyWith(
            color: LapseColors.light.ink,
            fontWeight: FontWeight.w700,
            fontFeatures: LapseTypography.tabular,
          ),
        ),
      ),
    );
  }
}
