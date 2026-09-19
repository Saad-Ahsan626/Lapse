import 'package:flutter/material.dart';

import 'package:lapse/core/theme/tokens/lapse_colors.dart';
import 'package:lapse/core/theme/tokens/lapse_typography.dart';

@immutable
class LapseTheme extends ThemeExtension<LapseTheme> {
  const LapseTheme({required this.colors, required this.text});

  factory LapseTheme.of(LapseColors colors) =>
      LapseTheme(colors: colors, text: LapseTypography.from(colors));

  final LapseColors colors;
  final LapseTypography text;

  @override
  LapseTheme copyWith({LapseColors? colors, LapseTypography? text}) =>
      LapseTheme(colors: colors ?? this.colors, text: text ?? this.text);

  @override
  LapseTheme lerp(covariant LapseTheme? other, double t) {
    if (other == null) return this;
    return LapseTheme(
      colors: colors.lerp(other.colors, t),
      text: text.lerp(other.text, t),
    );
  }
}

extension LapseThemeContext on BuildContext {
  LapseTheme get lapse => Theme.of(this).extension<LapseTheme>()!;
}
