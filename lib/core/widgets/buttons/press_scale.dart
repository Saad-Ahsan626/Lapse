import 'package:flutter/widgets.dart';

import 'package:lapse/core/motion/motion.dart';

class PressScale extends StatefulWidget {
  const PressScale({
    required this.child,
    this.enabled = true,
    this.scale = Motion.pressScale,
    super.key,
  });

  final Widget child;
  final bool enabled;
  final double scale;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _pressed = false;

  void _set(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final active = widget.enabled && !reduceMotion(context);
    return Listener(
      onPointerDown: active ? (_) => _set(true) : null,
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: active && _pressed ? widget.scale : 1,
        duration: _pressed ? Motion.press : Motion.release,
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
