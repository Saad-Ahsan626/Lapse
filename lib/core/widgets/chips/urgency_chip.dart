import 'dart:async';

import 'package:flutter/material.dart';

import 'package:lapse/core/domain/urgency.dart';
import 'package:lapse/core/motion/motion.dart';
import 'package:lapse/core/theme/lapse_theme.dart';
import 'package:lapse/core/theme/tokens/lapse_spacing.dart';

class UrgencyChip extends StatefulWidget {
  const UrgencyChip({required this.label, required this.urgency, super.key});

  final String label;
  final Urgency urgency;

  @override
  State<UrgencyChip> createState() => _UrgencyChipState();
}

class _UrgencyChipState extends State<UrgencyChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: Motion.urgentPulse,
  );

  bool get _shouldPulse =>
      widget.urgency == Urgency.urgent && !reduceMotion(context);

  void _syncPulse() {
    if (_shouldPulse) {
      if (!_pulse.isAnimating) unawaited(_pulse.repeat());
    } else {
      _pulse
        ..stop()
        ..value = 0;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncPulse();
  }

  @override
  void didUpdateWidget(UrgencyChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.urgency != widget.urgency) _syncPulse();
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lapse = context.lapse;
    final style = lapse.colors.urgencyChip(widget.urgency);
    final ringColor = lapse.colors.urgent;

    final chip = Container(
      constraints: const BoxConstraints(minHeight: Sizes.chipSmall),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: BorderRadius.circular(Radii.chipSmall),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: style.dot, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              widget.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: lapse.text.chipSmall.copyWith(color: style.foreground),
            ),
          ),
        ],
      ),
    );

    return Semantics(
      label: widget.label,
      excludeSemantics: true,
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _pulse,
          child: chip,
          builder: (context, child) {
            final t = _pulse.value;
            if (t < 0.8 || t > 0.9) return child!;
            final p = (t - 0.8) / 0.1;
            return DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(Radii.chipSmall),
                boxShadow: [
                  BoxShadow(
                    color: ringColor.withValues(alpha: 0.45 * (1 - p)),
                    spreadRadius: 7 * p,
                  ),
                ],
              ),
              child: child,
            );
          },
        ),
      ),
    );
  }
}
