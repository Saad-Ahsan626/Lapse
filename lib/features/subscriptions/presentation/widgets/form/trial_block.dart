import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:lapse/core/domain/currency_info.dart';
import 'package:lapse/core/motion/motion.dart';
import 'package:lapse/core/theme/theme.dart';
import 'package:lapse/core/widgets/widgets.dart';
import 'package:lapse/features/subscriptions/presentation/form/subscription_form_state.dart';

class TrialBlock extends StatelessWidget {
  const TrialBlock({
    required this.isTrial,
    required this.trialLengthDays,
    required this.currency,
    required this.priceController,
    required this.onTrialChanged,
    required this.onTrialLengthChanged,
    required this.onPriceChanged,
    required this.onCurrencyTap,
    this.priceError,
    super.key,
  });

  final bool isTrial;
  final int? trialLengthDays;
  final String currency;
  final String? priceError;
  final TextEditingController priceController;
  final ValueChanged<bool> onTrialChanged;
  final ValueChanged<int?> onTrialLengthChanged;
  final ValueChanged<String> onPriceChanged;
  final VoidCallback onCurrencyTap;

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
    final on = isTrial;
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
        onTap: () => onTrialChanged(!isTrial),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, Space.xs, Space.sm, Space.xs),
          child: Row(
            children: [
              if (isTrial) ...[
                const TrialBadge(),
                const SizedBox(width: 10),
              ],
              Expanded(child: Text('Free trial', style: lapse.text.itemTitle)),
              Switch(
                value: isTrial,
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
                  selected: trialLengthDays == days,
                  tone: LapseChipTone.trial,
                  onTint: true,
                  onTap: () => onTrialLengthChanged(days),
                ),
              LapseChip(
                label: 'Custom',
                selected: trialLengthDays == null,
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
    final error = priceError;
    final info = currencyInfo(currency);
    final valueStyle = lapse.text.itemTitle.copyWith(
      fontWeight: FontWeight.w700,
      fontFeatures: LapseTypography.tabular,
    );
    final stacked = MediaQuery.textScalerOf(context).scale(1) > 1.5;
    final Widget label = ExcludeSemantics(
      child: Text(
        'Price after trial',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: lapse.text.body.copyWith(
          fontWeight: FontWeight.w600,
          color: c.inkMuted,
        ),
      ),
    );
    final Widget value = Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        ExcludeSemantics(
          child: Text(
            info.symbol,
            style: valueStyle,
          ),
        ),
        const SizedBox(width: 5),
        Flexible(
          child: ListenableBuilder(
            listenable: priceController,
            builder: (context, child) => SizedBox(
              width: math.max(
                Sizes.minTap,
                _inputWidth(context, valueStyle),
              ),
              child: child,
            ),
            child: Semantics(
              label: 'Price after trial',
              child: TextField(
                controller: priceController,
                onChanged: onPriceChanged,
                keyboardType: const TextInputType.numberWithOptions(
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
        _CurrencySuffix(info: info, onTap: onCurrencyTap),
      ],
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
              child: stacked
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: Space.sm),
                          child: label,
                        ),
                        value,
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(child: label),
                        const SizedBox(width: Space.md),
                        Expanded(child: value),
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

class _CurrencySuffix extends StatelessWidget {
  const _CurrencySuffix({required this.info, required this.onTap});

  final CurrencyInfo info;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final lapse = context.lapse;
    return Semantics(
      button: true,
      label: 'Currency, ${info.code}. Change currency',
      excludeSemantics: true,
      onTap: onTap,
      child: GestureDetector(
        key: const ValueKey('trial-currency-suffix'),
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: Sizes.minTap,
            minHeight: Sizes.minTap,
          ),
          child: Padding(
            padding: const EdgeInsets.only(left: Space.sm),
            child: Center(
              widthFactor: 1,
              child: Text(
                info.code,
                style: lapse.text.chip.copyWith(color: lapse.colors.primary),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
