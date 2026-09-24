import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'package:lapse/core/motion/motion.dart';

class StaggeredEntrance extends StatefulWidget {
  const StaggeredEntrance({
    required this.index,
    required this.child,
    this.animate = true,
    super.key,
  });

  final int index;
  final Widget child;
  final bool animate;

  static const double offset = 12;
  static const int maxSteps = 8;

  static Duration delayFor(int index) =>
      Motion.stagger * math.min(math.max(index, 0), maxSteps);

  @override
  State<StaggeredEntrance> createState() => _StaggeredEntranceState();
}

class _StaggeredEntranceState extends State<StaggeredEntrance>
    with SingleTickerProviderStateMixin {
  late final Duration _delay = StaggeredEntrance.delayFor(widget.index);
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _delay + Motion.listItem,
  );
  late final Animation<double> _curve = CurvedAnimation(
    parent: _controller,
    curve: Interval(
      _delay.inMicroseconds / (_delay + Motion.listItem).inMicroseconds,
      1,
      curve: Motion.emphasized,
    ),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = reduceMotion(context);
    if (_started) {
      if (reduce) _controller.value = 1;
      return;
    }
    _started = true;
    if (!widget.animate || reduce) {
      _controller.value = 1;
    } else {
      unawaited(_controller.forward());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _curve,
      child: MatrixTransition(
        animation: _curve,
        onTransform: (t) => Matrix4.translationValues(
          0,
          StaggeredEntrance.offset * (1 - t),
          0,
        ),
        child: widget.child,
      ),
    );
  }
}
