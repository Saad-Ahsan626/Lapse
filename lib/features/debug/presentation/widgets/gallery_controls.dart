import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lapse/core/widgets/widgets.dart';
import 'package:lapse/features/settings/domain/entities/app_theme_mode.dart';
import 'package:lapse/features/settings/presentation/providers/settings_providers.dart';

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
    final mode = ref.watch(settingsProvider.select((s) => s.themeMode));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          children: [
            for (final m in AppThemeMode.values)
              LapseChip(
                label: switch (m) {
                  AppThemeMode.system => 'System',
                  AppThemeMode.light => 'Light',
                  AppThemeMode.dark => 'Dark',
                },
                selected: mode == m,
                onTap: () =>
                    ref.read(settingsProvider.notifier).setThemeMode(m),
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
