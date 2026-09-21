import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lapse/core/formatting/money_formatter.dart';
import 'package:lapse/core/theme/theme.dart';
import 'package:lapse/core/widgets/widgets.dart';
import 'package:lapse/features/onboarding/domain/example_price.dart';
import 'package:lapse/features/settings/presentation/providers/settings_providers.dart';

class ChargeIllustration extends ConsumerWidget {
  const ChargeIllustration({super.key});

  static const double _disc = 170;
  static const double _ring = 150;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency = ref.watch(
      settingsProvider.select((s) => s.defaultCurrency),
    );
    final lapse = context.lapse;
    final c = lapse.colors;
    final text = lapse.text;
    final amount = formatMoney(exampleTrialPrice(currency));

    return ExcludeSemantics(
      child: MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1.2,
        child: SizedBox(
          width: 256,
          height: 210,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 0,
                top: 0,
                child: Container(
                  width: _disc,
                  height: _disc,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: c.primaryTint,
                    shape: BoxShape.circle,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Transform.flip(
                        flipX: true,
                        child: CountdownRing(
                          progress: 0.16,
                          color: c.urgent,
                          size: _ring,
                          strokeRatio: 0.07,
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Trial', style: text.meta),
                          Text(
                            'Day 7',
                            style: text.section.copyWith(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 94,
                top: 126,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 150),
                  padding: const EdgeInsets.fromLTRB(
                    Space.lg,
                    Space.md,
                    Space.lg,
                    Space.md,
                  ),
                  decoration: BoxDecoration(
                    color: c.surface,
                    borderRadius: BorderRadius.circular(Radii.md),
                    border: Border.all(color: c.border),
                    boxShadow: c.cardShadow,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CHARGED',
                        style: text.badge.copyWith(
                          color: c.urgentText,
                          fontSize: 10,
                        ),
                      ),
                      Text(
                        amount,
                        style: text.section.copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'today, 4:02 AM',
                        style: text.meta.copyWith(fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
