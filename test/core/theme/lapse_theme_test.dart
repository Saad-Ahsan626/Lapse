import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lapse/core/theme/app_theme.dart';
import 'package:lapse/core/theme/lapse_theme.dart';
import 'package:lapse/core/theme/tokens/lapse_colors.dart';

void main() {
  test('both themes carry the Lapse extension with matching brightness', () {
    final light = AppTheme.light();
    final dark = AppTheme.dark();

    expect(light.extension<LapseTheme>()!.colors.isDark, isFalse);
    expect(dark.extension<LapseTheme>()!.colors.isDark, isTrue);
    expect(light.brightness, Brightness.light);
    expect(dark.brightness, Brightness.dark);
  });

  test('uses the design primary colours', () {
    expect(AppTheme.light().colorScheme.primary, const Color(0xFF4F46E5));
    expect(AppTheme.dark().colorScheme.primary, const Color(0xFF818CF8));
    expect(
      AppTheme.dark().scaffoldBackgroundColor,
      const Color(0xFF0B0B12),
    );
  });

  test('lerp blends light → dark (so theme switches animate)', () {
    final light = LapseTheme.of(LapseColors.light);
    final dark = LapseTheme.of(LapseColors.dark);

    final mid = light.lerp(dark, 0.5);

    expect(
      mid.colors.background,
      Color.lerp(LapseColors.light.background, LapseColors.dark.background, .5),
    );
    expect(light.lerp(dark, 0).colors.primary, LapseColors.light.primary);
    expect(light.lerp(dark, 1).colors.primary, LapseColors.dark.primary);
  });

  test('money styles use tabular figures', () {
    final text = LapseTheme.of(LapseColors.light).text;

    expect(
      text.moneyHero.fontFeatures,
      contains(const FontFeature.tabularFigures()),
    );
    expect(
      text.meta.fontFeatures,
      contains(const FontFeature.tabularFigures()),
    );
  });
}
