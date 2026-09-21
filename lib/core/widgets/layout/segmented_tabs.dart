import 'package:flutter/material.dart';

import 'package:lapse/core/motion/motion.dart';
import 'package:lapse/core/theme/lapse_theme.dart';
import 'package:lapse/core/theme/tokens/lapse_spacing.dart';
import 'package:lapse/core/widgets/layout/segmented_tab.dart';

class SegmentedTabs<T> extends StatelessWidget {
  const SegmentedTabs({
    required this.tabs,
    required this.selected,
    required this.onChanged,
    this.selectedColor,
    super.key,
  });

  final List<SegmentedTab<T>> tabs;
  final T selected;
  final ValueChanged<T> onChanged;
  final Color? selectedColor;

  static const double _padding = 4;
  static const double _segmentRadius = 11;

  @override
  Widget build(BuildContext context) {
    final c = context.lapse.colors;
    final isDark = c.brightness == Brightness.dark;
    final index = tabs.indexWhere((t) => t.value == selected);
    final count = tabs.length;
    final x = count <= 1 || index < 0 ? -1.0 : -1 + 2 * index / (count - 1);

    return Container(
      constraints: const BoxConstraints(minHeight: Sizes.minTap),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: c.surfaceMuted,
        borderRadius: BorderRadius.circular(Radii.control),
      ),
      child: Stack(
        children: [
          if (index >= 0)
            Positioned.fill(
              left: _padding,
              top: _padding,
              right: _padding,
              bottom: _padding,
              child: AnimatedAlign(
                alignment: Alignment(x, 0),
                duration: reduceMotion(context) ? Duration.zero : Motion.snap,
                curve: Curves.easeOutCubic,
                child: FractionallySizedBox(
                  widthFactor: 1 / count,
                  heightFactor: 1,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: selectedColor ?? (isDark ? c.tile : c.surface),
                      borderRadius: BorderRadius.circular(_segmentRadius),
                      boxShadow: c.cardShadow,
                    ),
                  ),
                ),
              ),
            ),
          Material(
            type: MaterialType.transparency,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final tab in tabs)
                    Expanded(
                      child: _Segment<T>(
                        tab: tab,
                        selected: tab.value == selected,
                        onTap: () => onChanged(tab.value),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Segment<T> extends StatelessWidget {
  const _Segment({
    required this.tab,
    required this.selected,
    required this.onTap,
  });

  final SegmentedTab<T> tab;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.lapse.colors;
    final text = context.lapse.text;
    final count = tab.count;

    return Semantics(
      button: true,
      selected: selected,
      label: tab.semanticLabel,
      onTap: onTap,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(SegmentedTabs._segmentRadius),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: Sizes.minTap,
            minHeight: Sizes.minTap,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Space.xs + SegmentedTabs._padding,
              vertical: Space.sm + SegmentedTabs._padding,
            ),
            child: Center(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: tab.label,
                      style: text.chip.copyWith(
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w600,
                        color: selected ? c.ink : c.inkMuted,
                      ),
                    ),
                    if (count != null)
                      TextSpan(
                        text: ' $count',
                        style: text.chipSmall.copyWith(
                          color: selected ? c.primary : c.inkSubtle,
                        ),
                      ),
                  ],
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
