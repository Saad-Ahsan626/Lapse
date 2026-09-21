import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import 'package:lapse/core/motion/motion.dart';
import 'package:lapse/core/theme/lapse_theme.dart';
import 'package:lapse/core/theme/tokens/lapse_spacing.dart';
import 'package:lapse/core/widgets/layout/swipe_action.dart';
import 'package:lapse/core/widgets/layout/swipe_actions_group.dart';

class SwipeActions extends StatefulWidget {
  const SwipeActions({
    required this.actions,
    required this.child,
    this.borderRadius = Radii.card,
    this.actionWidth = 84,
    super.key,
  });

  final List<SwipeAction> actions;
  final Widget child;
  final double borderRadius;
  final double actionWidth;

  static const double openThreshold = 0.4;
  static const double flingVelocity = 365;
  static const Duration snap = Motion.snap;

  @override
  State<SwipeActions> createState() => _SwipeActionsState();
}

class _SwipeActionsState extends State<SwipeActions>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: SwipeActions.snap,
  )..addStatusListener(_onStatus);
  ScrollPosition? _scrollPosition;
  SwipeActionsGroupState? _group;

  double get _total => widget.actions.length * widget.actionWidth;

  bool get _isOpen => _controller.value > 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _group = SwipeActionsGroup.maybeOf(context);
    final position = Scrollable.maybeOf(context)?.position;
    if (!identical(position, _scrollPosition)) {
      _scrollPosition?.isScrollingNotifier.removeListener(_onScroll);
      _scrollPosition = position;
      _scrollPosition?.isScrollingNotifier.addListener(_onScroll);
    }
  }

  @override
  void dispose() {
    _scrollPosition?.isScrollingNotifier.removeListener(_onScroll);
    _group?.didClose(this);
    _controller.dispose();
    super.dispose();
  }

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.dismissed) _group?.didClose(this);
  }

  void _onScroll() {
    final scrolling = _scrollPosition?.isScrollingNotifier.value ?? false;
    if (scrolling && _isOpen) _close();
  }

  void _animateTo(double target) {
    if (!mounted) return;
    if (target > 0) _group?.didOpen(this, _close);
    if (reduceMotion(context)) {
      _controller.value = target;
      return;
    }
    unawaited(
      _controller.animateTo(
        target,
        duration: SwipeActions.snap,
        curve: Curves.easeOutCubic,
      ),
    );
  }

  void _open() => _animateTo(1);

  void _close() {
    if (_controller.value == 0 && !_controller.isAnimating) return;
    _animateTo(0);
  }

  void _onDragStart(DragStartDetails details) {
    _controller.stop();
    _group?.didOpen(this, _close);
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (_total <= 0) return;
    final delta = details.primaryDelta ?? details.delta.dx;
    _controller.value = (_controller.value - delta / _total).clamp(0.0, 1.0);
  }

  void _onDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity <= -SwipeActions.flingVelocity) {
      _open();
    } else if (velocity >= SwipeActions.flingVelocity) {
      _close();
    } else if (_controller.value > SwipeActions.openThreshold) {
      _open();
    } else {
      _close();
    }
  }

  void _trigger(SwipeAction action) {
    _close();
    action.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final total = _total;
    return TapRegion(
      onTapOutside: (_) => _close(),
      child: Semantics(
        customSemanticsActions: {
          for (final action in widget.actions)
            CustomSemanticsAction(label: action.label): () => _trigger(action),
        },
        child: GestureDetector(
          excludeFromSemantics: true,
          onHorizontalDragStart: _onDragStart,
          onHorizontalDragUpdate: _onDragUpdate,
          onHorizontalDragEnd: _onDragEnd,
          child: AnimatedBuilder(
            animation: _controller,
            child: widget.child,
            builder: (context, child) {
              final revealed = _controller.value * total;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  if (revealed > 0)
                    Positioned(
                      top: 0,
                      bottom: 0,
                      right: 0,
                      width: revealed,
                      child: _ActionsLayer(
                        actions: widget.actions,
                        actionWidth: widget.actionWidth,
                        borderRadius: widget.borderRadius,
                        onTrigger: _trigger,
                      ),
                    ),
                  Transform.translate(
                    offset: Offset(-revealed, 0),
                    child: Stack(
                      children: [
                        child!,
                        if (revealed > 0)
                          Positioned.fill(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              excludeFromSemantics: true,
                              onTap: _close,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ActionsLayer extends StatelessWidget {
  const _ActionsLayer({
    required this.actions,
    required this.actionWidth,
    required this.borderRadius,
    required this.onTrigger,
  });

  final List<SwipeAction> actions;
  final double actionWidth;
  final double borderRadius;
  final ValueChanged<SwipeAction> onTrigger;

  @override
  Widget build(BuildContext context) {
    final width = actions.length * actionWidth;
    return ClipRRect(
      borderRadius: BorderRadius.horizontal(
        right: Radius.circular(borderRadius),
      ),
      child: OverflowBox(
        alignment: Alignment.centerRight,
        minWidth: width,
        maxWidth: width,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final action in actions)
              SizedBox(
                width: actionWidth,
                child: _ActionButton(
                  action: action,
                  onTap: () => onTrigger(action),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.action, required this.onTap});

  final SwipeAction action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = context.lapse.text.chipSmall.copyWith(
      color: action.foregroundColor,
      fontWeight: FontWeight.w700,
    );
    return Semantics(
      button: true,
      label: action.label,
      onTap: onTap,
      excludeSemantics: true,
      child: Material(
        color: action.color,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.xs),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(action.icon, size: 20, color: action.foregroundColor),
                  const SizedBox(height: Space.xs),
                  Text(action.label, style: label, maxLines: 1),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
