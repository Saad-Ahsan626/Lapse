import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lapse/app/providers/theme_mode_provider.dart';
import 'package:lapse/core/widgets/widgets.dart';

class GalleryControls extends ConsumerWidget {
  const GalleryControls({
    required this.reduceMotion,
    required this.onReduceMotionChanged,
    super.key,
  });

  final bool reduceMotion;
  final ValueChanged<bool> onReduceMotionChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          children: [
            for (final m in ThemeMode.values)
              LapseChip(
                label: switch (m) {
                  ThemeMode.system => 'System',
                  ThemeMode.light => 'Light',
                  ThemeMode.dark => 'Dark',
                },
                selected: mode == m,
                onTap: () => ref.read(themeModeProvider.notifier).mode = m,
              ),
          ],
        ),
        LapseSwitchRow(
          label: 'Simulate reduce motion',
          value: reduceMotion,
          onChanged: onReduceMotionChanged,
        ),
      ],
    );
  }
}
