import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lapse/core/theme/theme.dart';
import 'package:lapse/core/widgets/widgets.dart';
import 'package:lapse/features/settings/domain/entities/app_theme_mode.dart';
import 'package:lapse/features/settings/presentation/providers/settings_providers.dart';

class ThemeSegmentedRow extends ConsumerWidget {
  const ThemeSegmentedRow({super.key});

  static const List<SegmentedTab<AppThemeMode>> tabs = [
    SegmentedTab(value: AppThemeMode.system, label: 'System'),
    SegmentedTab(value: AppThemeMode.light, label: 'Light'),
    SegmentedTab(value: AppThemeMode.dark, label: 'Dark'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lapse = context.lapse;
    final mode = ref.watch(
      settingsProvider.select((settings) => settings.themeMode),
    );
    return Padding(
      padding: const EdgeInsets.all(Space.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            header: true,
            child: Text('Theme', style: lapse.text.itemTitle),
          ),
          const SizedBox(height: Space.md),
          SegmentedTabs<AppThemeMode>(
            tabs: tabs,
            selected: mode,
            selectedColor: lapse.colors.brightness == Brightness.dark
                ? Color.alphaBlend(lapse.colors.primaryTint, lapse.colors.tile)
                : null,
            onChanged: (next) => unawaited(
              ref.read(settingsProvider.notifier).setThemeMode(next),
            ),
          ),
        ],
      ),
    );
  }
}
