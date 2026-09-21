import 'package:flutter/material.dart';

import 'package:lapse/core/domain/money.dart';
import 'package:lapse/core/formatting/money_formatter.dart';
import 'package:lapse/core/theme/theme.dart';
import 'package:lapse/core/widgets/widgets.dart';
import 'package:lapse/features/savings/presentation/celebration_result.dart';

class CelebrationSheet extends StatelessWidget {
  const CelebrationSheet({
    required this.headline,
    required this.saved,
    required this.body,
    this.playConfetti = true,
    super.key,
  });

  final String headline;
  final Money saved;
  final String body;
  final bool playConfetti;

  @override
  Widget build(BuildContext context) {
    final c = context.lapse.colors;
    final text = context.lapse.text;
    final navigator = Navigator.of(context);

    return Stack(
      children: [
        SingleChildScrollView(
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                Space.screen,
                Space.sm,
                Space.screen,
                Space.lg,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(child: SavingsBadge()),
                  const SizedBox(height: Space.xl),
                  Text(
                    headline,
                    textAlign: TextAlign.center,
                    style: text.meta.copyWith(
                      color: c.inkMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (saved.isPositive) ...[
                    const SizedBox(height: Space.xs),
                    CountUpText(
                      value: saved.minor,
                      format: (minor) =>
                          formatMoney(Money(minor, saved.currency)),
                      textAlign: TextAlign.center,
                      style: text.moneyHero.copyWith(
                        color: c.savings,
                        fontSize: 44,
                      ),
                    ),
                    Text(
                      'saved per year',
                      textAlign: TextAlign.center,
                      style: text.body.copyWith(
                        color: c.savingsText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(height: Space.xl),
                  Semantics(
                    header: true,
                    child: Text(
                      'Nice move.',
                      textAlign: TextAlign.center,
                      style: text.title.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(height: Space.sm),
                  Text(
                    body,
                    textAlign: TextAlign.center,
                    style: text.bodyMuted,
                  ),
                  const SizedBox(height: Space.xxl),
                  LapseButton(
                    label: 'Done',
                    variant: LapseButtonVariant.inverse,
                    expand: true,
                    onPressed: () => navigator.pop(CelebrationResult.done),
                  ),
                  const SizedBox(height: Space.xs),
                  Center(
                    child: LapseButton(
                      label: 'Undo',
                      variant: LapseButtonVariant.text,
                      foregroundColor: c.inkSubtle,
                      onPressed: () => navigator.pop(CelebrationResult.undo),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: ConfettiBurst(play: playConfetti),
        ),
      ],
    );
  }
}
