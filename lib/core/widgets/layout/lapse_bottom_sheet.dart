import 'package:flutter/material.dart';

import 'package:lapse/core/motion/motion.dart';
import 'package:lapse/core/theme/lapse_theme.dart';
import 'package:lapse/core/theme/tokens/lapse_spacing.dart';
import 'package:lapse/core/widgets/layout/lapse_sheet_route.dart';

Future<T?> showLapseSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  String? title,
  bool showClose = true,
  bool isScrollControlled = true,
  double maxHeightFactor = 0.92,
  Duration? duration,
  Curve? curve,
}) {
  final c = context.lapse.colors;
  final reduce = reduceMotion(context);
  const instant = Duration(milliseconds: 1);

  return Navigator.of(context).push(
    LapseSheetRoute<T>(
      context: context,
      entranceCurve: reduce ? null : curve,
      isScrollControlled: isScrollControlled,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: c.background,
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.sheet)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * maxHeightFactor,
      ),
      sheetAnimationStyle: AnimationStyle(
        duration: reduce ? instant : duration ?? Motion.sheet,
        curve: curve ?? Curves.easeOutCubic,
        reverseDuration: reduce ? instant : Motion.fade,
        reverseCurve: Curves.easeInCubic,
      ),
      builder: (sheetContext) {
        final lapse = sheetContext.lapse;
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (title != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    Space.screen,
                    Space.sm,
                    Space.screen,
                    Space.md,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Semantics(
                          header: true,
                          child: Text(title, style: lapse.text.title),
                        ),
                      ),
                      if (showClose) ...[
                        const SizedBox(width: Space.md),
                        Semantics(
                          button: true,
                          label: 'Close',
                          excludeSemantics: true,
                          onTap: () => Navigator.of(sheetContext).pop(),
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => Navigator.of(sheetContext).pop(),
                            child: SizedBox.square(
                              dimension: Sizes.minTap,
                              child: Center(
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: lapse.colors.surfaceMuted,
                                    shape: BoxShape.circle,
                                  ),
                                  child: SizedBox.square(
                                    dimension: 36,
                                    child: Icon(
                                      Icons.close_rounded,
                                      size: 20,
                                      color: lapse.colors.ink,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              Flexible(child: builder(sheetContext)),
            ],
          ),
        );
      },
    ),
  );
}
