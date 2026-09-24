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
    duration: Motion.urgentPulse ~/ 10,
  );
  Timer? _timer;

  bool get _shouldPulse =>
      widget.urgency == Urgency.urgent && !reduceMotion(context);

  void _syncPulse() {
    if (_shouldPulse) {
      _timer ??= Timer.periodic(Motion.urgentPulse, (_) {
        unawaited(_pulse.forward(from: 0));
      });
    } else {
      _stopPulse();
    }
  }

  void _stopPulse() {
    _timer?.cancel();
    _timer = null;
    _pulse
      ..stop()
      ..value = 0;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncPulse();
  }

  @override
  void didUpdateWidget(UrgencyChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.urgency != widget.urgency) {
      _stopPulse();
      _syncPulse();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
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
            final p = _pulse.value;
            final active = _pulse.isAnimating;
            return DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(Radii.chipSmall),
                boxShadow: [
                  BoxShadow(
                    color: active
                        ? ringColor.withValues(alpha: 0.45 * (1 - p))
                        : ringColor.withValues(alpha: 0),
                    spreadRadius: active ? 7 * p : 0,
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
