import 'dart:async';

import 'package:flutter/widgets.dart';

import 'package:lapse/core/motion/motion.dart';
import 'package:lapse/core/theme/tokens/lapse_typography.dart';

class CountUpText extends StatefulWidget {
  const CountUpText({
    required this.value,
    required this.format,
    this.style,
    this.duration = Motion.countUp,
    this.textAlign,
    super.key,
  });

  final int value;
  final String Function(int value) format;
  final TextStyle? style;
  final Duration duration;
  final TextAlign? textAlign;

  @override
  State<CountUpText> createState() => _CountUpTextState();
}

class _CountUpTextState extends State<CountUpText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  late final Animation<double> _curve = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
  );
  int _from = 0;
  bool _started = false;

  int get _current {
    final t = _curve.value;
    return (_from + (widget.value - _from) * t).round();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _run();
  }

  @override
  void didUpdateWidget(CountUpText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration != widget.duration) {
      _controller.duration = widget.duration;
    }
    if (oldWidget.value != widget.value) {
      _from = _displayed(oldWidget.value);
      _run();
    }
  }

  int _displayed(int oldTarget) {
    final t = _curve.value;
    return (_from + (oldTarget - _from) * t).round();
  }

  void _run() {
    if (reduceMotion(context) || widget.duration == Duration.zero) {
      _controller.value = 1;
      return;
    }
    _controller.value = 0;
    unawaited(_controller.forward());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = widget.style ?? DefaultTextStyle.of(context).style;
    final style = base.copyWith(fontFeatures: LapseTypography.tabular);
    final instant = reduceMotion(context);
    return Semantics(
      label: widget.format(widget.value),
      excludeSemantics: true,
      child: AnimatedBuilder(
        animation: _curve,
        builder: (context, _) => Text(
          widget.format(instant ? widget.value : _current),
          style: style,
          textAlign: widget.textAlign,
        ),
      ),
    );
  }
}
