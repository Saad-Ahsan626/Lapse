import 'package:flutter/material.dart';

class LapseSheetRoute<T> extends ModalBottomSheetRoute<T> {
  factory LapseSheetRoute({
    required BuildContext context,
    required WidgetBuilder builder,
    required bool isScrollControlled,
    required bool showDragHandle,
    required bool useSafeArea,
    Curve? entranceCurve,
    Color? backgroundColor,
    ShapeBorder? shape,
    Clip? clipBehavior,
    BoxConstraints? constraints,
    AnimationStyle? sheetAnimationStyle,
  }) {
    final navigator = Navigator.of(context);
    final localizations = MaterialLocalizations.of(context);
    final contentKey = GlobalKey(debugLabel: 'LapseSheetRoute content');
    return LapseSheetRoute._(
      contentKey: contentKey,
      entranceCurve: entranceCurve,
      builder: (context) =>
          KeyedSubtree(key: contentKey, child: builder(context)),
      capturedThemes: InheritedTheme.capture(
        from: context,
        to: navigator.context,
      ),
      isScrollControlled: isScrollControlled,
      barrierLabel: localizations.scrimLabel,
      barrierOnTapHint: localizations.scrimOnTapHint(
        localizations.bottomSheetLabel,
      ),
      backgroundColor: backgroundColor,
      shape: shape,
      clipBehavior: clipBehavior,
      constraints: constraints,
      modalBarrierColor: Theme.of(context).bottomSheetTheme.modalBarrierColor,
      showDragHandle: showDragHandle,
      useSafeArea: useSafeArea,
      sheetAnimationStyle: sheetAnimationStyle,
    );
  }

  LapseSheetRoute._({
    required GlobalKey contentKey,
    required this.entranceCurve,
    required super.builder,
    required super.isScrollControlled,
    super.capturedThemes,
    super.barrierLabel,
    super.barrierOnTapHint,
    super.backgroundColor,
    super.shape,
    super.clipBehavior,
    super.constraints,
    super.modalBarrierColor,
    super.showDragHandle,
    super.useSafeArea,
    super.sheetAnimationStyle,
  }) : _contentKey = contentKey;

  static const Curve materialCurve = Easing.legacyDecelerate;

  final Curve? entranceCurve;
  final GlobalKey _contentKey;
  bool _entered = false;

  @override
  void install() {
    super.install();
    animation!.addStatusListener(_trackEntrance);
  }

  void _trackEntrance(AnimationStatus status) {
    if (status != AnimationStatus.forward) _entered = true;
  }

  double get _sheetHeight {
    final box = _contentKey.currentContext?.findRenderObject();
    return box is RenderBox && box.hasSize ? box.size.height : 0;
  }

  double entranceOffset(double t) {
    final curve = entranceCurve;
    if (curve == null || _entered) return 0;
    return (materialCurve.transform(t) - curve.transform(t)) * _sheetHeight;
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (entranceCurve == null) return child;
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) {
        final dy = entranceOffset(animation.value);
        final moved = Transform.translate(offset: Offset(0, dy), child: child);
        final fill = backgroundColor;
        if (dy >= 0 || fill == null) return moved;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: -dy + 1,
              child: IgnorePointer(
                child: ExcludeSemantics(child: ColoredBox(color: fill)),
              ),
            ),
            moved,
          ],
        );
      },
    );
  }
}
