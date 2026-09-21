import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:lapse/core/domain/currency_info.dart';
import 'package:lapse/core/motion/motion.dart';
import 'package:lapse/core/theme/theme.dart';
import 'package:lapse/core/widgets/widgets.dart';
import 'package:lapse/features/subscriptions/domain/validation/subscription_field.dart';
import 'package:lapse/features/subscriptions/presentation/form/subscription_form_state.dart';

class TrialBlock extends StatelessWidget {
  const TrialBlock({
    required this.state,
    required this.priceController,
    required this.onTrialChanged,
    required this.onTrialLengthChanged,
    required this.onPriceChanged,
    super.key,
  });

  final SubscriptionFormState state;
  final TextEditingController priceController;
  final ValueChanged<bool> onTrialChanged;
  final ValueChanged<int?> onTrialLengthChanged;
  final ValueChanged<String> onPriceChanged;

  static Duration get revealDuration => Motion.expand + Motion.fieldFade;

  static Curve get revealCurve => Interval(
    Motion.expand.inMicroseconds / revealDuration.inMicroseconds,
    1,
    curve: Curves.easeOut,
  );

  @override
  Widget build(BuildContext context) {
    final lapse = context.lapse;
    final c = lapse.colors;
    final on = state.isTrial;
    final reduce = reduceMotion(context);

    return AnimatedContainer(
      duration: reduce ? Duration.zero : Motion.expand,
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: on ? c.trial.withValues(alpha: 0.09) : c.inputFill,
        borderRadius: BorderRadius.circular(Radii.card),
        border: Border.all(
          color: on ? c.trial.withValues(alpha: 0.25) : c.inputBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _switchRow(context),
          if (reduce)
            on ? _expanded(context) : const SizedBox(width: double.infinity)
          else
            AnimatedSize(
              duration: Motion.expand,
              curve: Curves.easeOut,
              alignment: Alignment.topCenter,
              child: AnimatedSwitcher(
                duration: revealDuration,
                reverseDuration: Motion.fieldFade,
                switchInCurve: revealCurve,
                layoutBuilder: (current, previous) => Stack(
                  alignment: Alignment.topCenter,
                  children: [...previous, ?current],
                ),
                child: on
                    ? _expanded(context)
                    : const SizedBox(width: double.infinity),
              ),
            ),
        ],
      ),
    );
  }

  Widget _switchRow(BuildContext context) {
    final lapse = context.lapse;
    final c = lapse.colors;
    return MergeSemantics(
      child: InkWell(
        borderRadius: BorderRadius.circular(Radii.card),
        onTap: () => onTrialChanged(!state.isTrial),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, Space.xs, Space.sm, Space.xs),
          child: Row(
            children: [
              if (state.isTrial) ...[
                const TrialBadge(),
                const SizedBox(width: 10),
              ],
              Expanded(child: Text('Free trial', style: lapse.text.itemTitle)),
              Switch(
                value: state.isTrial,
                onChanged: onTrialChanged,
                activeTrackColor: c.trial,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _expanded(BuildContext context) {
    final lapse = context.lapse;
    final c = lapse.colors;
    return Padding(
      key: const ValueKey('trial-expanded'),
      padding: const EdgeInsets.fromLTRB(
        Space.md,
        Space.xs,
        Space.md,
        Space.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ExcludeSemantics(
            child: Text(
              'TRIAL LENGTH',
              style: lapse.text.caption.copyWith(color: c.trialText),
            ),
          ),
          const SizedBox(height: Space.xs),
          Wrap(
            spacing: 6,
            children: [
              for (final days in SubscriptionFormState.trialLengths)
                LapseChip(
                  label: '${days}d',
                  selected: state.trialLengthDays == days,
                  tone: LapseChipTone.trial,
                  onTint: true,
                  onTap: () => onTrialLengthChanged(days),
                ),
              LapseChip(
                label: 'Custom',
                selected: state.trialLengthDays == null,
                tone: LapseChipTone.trial,
                onTint: true,
                onTap: () => onTrialLengthChanged(null),
              ),
            ],
          ),
          const SizedBox(height: Space.sm),
          _priceRow(context),
        ],
      ),
    );
  }

  double _inputWidth(BuildContext context, TextStyle style) {
    final text = priceController.text.isEmpty ? '0' : priceController.text;
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    final width = painter.width + 4;
    painter.dispose();
    return width;
  }

  Widget _priceRow(BuildContext context) {
    final lapse = context.lapse;
    final c = lapse.colors;
    final error = state.errors[SubscriptionField.price];
    final valueStyle = lapse.text.itemTitle.copyWith(
      fontWeight: FontWeight.w700,
      fontFeatures: LapseTypography.tabular,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(Radii.sm),
            border: Border.all(
              color: error == null
                  ? c.inputBorder
                  : c.urgent.withValues(alpha: 0.5),
            ),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 49),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: Space.lg),
              child: Row(
                children: [
                  Expanded(
                    child: ExcludeSemantics(
                      child: Text(
                        'Price after trial',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: lapse.text.body.copyWith(
                          fontWeight: FontWeight.w600,
                          color: c.inkMuted,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: Space.md),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) => Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ExcludeSemantics(
                            child: Text(
                              currencyInfo(state.currency).symbol,
                              style: valueStyle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: math.max(40, constraints.maxWidth - 40),
                            ),
                            child: SizedBox(
                              width: math.max(
                                Sizes.minTap,
                                _inputWidth(context, valueStyle),
                              ),
                              child: Semantics(
                                label: 'Price after trial',
                                child: TextField(
                                  controller: priceController,
                                  onChanged: onPriceChanged,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                      RegExp('[0-9.,]'),
                                    ),
                                  ],
                                  textAlign: TextAlign.end,
                                  style: valueStyle,
                                  decoration: InputDecoration(
                                    isCollapsed: true,
                                    contentPadding: const EdgeInsets.symmetric(
                                      vertical: 15,
                                    ),
                                    border: InputBorder.none,
                                    hintText: '0',
                                    hintStyle: valueStyle.copyWith(
                                      color: c.inkSubtle,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.error_outline_rounded, size: 15, color: c.urgentText),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  error,
                  style: lapse.text.meta.copyWith(color: c.urgentText),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
