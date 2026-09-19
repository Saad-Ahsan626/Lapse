import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lapse/core/theme/lapse_theme.dart';
import 'package:lapse/core/theme/tokens/lapse_colors.dart';
import 'package:lapse/core/theme/tokens/lapse_spacing.dart';
import 'package:lapse/core/theme/tokens/lapse_typography.dart';

abstract final class AppTheme {
  static ThemeData light() => _build(LapseColors.light);
  static ThemeData dark() => _build(LapseColors.dark);

  static ThemeData _build(LapseColors c) {
    final lapse = LapseTheme.of(c);
    final t = lapse.text;

    final scheme = ColorScheme(
      brightness: c.brightness,
      primary: c.primary,
      onPrimary: c.onPrimary,
      secondary: c.trial,
      onSecondary: c.onTrial,
      tertiary: c.savings,
      onTertiary: Colors.white,
      error: c.urgent,
      onError: Colors.white,
      surface: c.surface,
      onSurface: c.ink,
      onSurfaceVariant: c.inkMuted,
      surfaceContainerLowest: c.background,
      surfaceContainerLow: c.inputFill,
      surfaceContainer: c.surfaceMuted,
      surfaceContainerHigh: c.surfaceMuted,
      surfaceContainerHighest: c.tile,
      outline: c.borderStrong,
      outlineVariant: c.border,
      shadow: Colors.black,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: c.brightness,
      colorScheme: scheme,
      fontFamily: LapseTypography.fontFamily,
      scaffoldBackgroundColor: c.background,
      canvasColor: c.background,
      splashFactory: InkRipple.splashFactory,
      splashColor: c.primary.withValues(alpha: 0.06),
      highlightColor: Colors.transparent,
      extensions: [lapse],
      textTheme: TextTheme(
        displaySmall: t.moneyHero,
        headlineSmall: t.title,
        titleLarge: t.title,
        titleMedium: t.section,
        titleSmall: t.itemTitle,
        bodyLarge: t.body,
        bodyMedium: t.body,
        bodySmall: t.meta,
        labelLarge: t.button,
        labelMedium: t.chip,
        labelSmall: t.caption,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: c.background,
        foregroundColor: c.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: t.section,
        systemOverlayStyle: overlayStyle(c.brightness),
      ),
      iconTheme: IconThemeData(color: c.ink, size: 22),
      dividerTheme: DividerThemeData(color: c.border, thickness: 1, space: 1),
      switchTheme: SwitchThemeData(
        thumbColor: const WidgetStatePropertyAll(Colors.white),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? c.primary : c.borderStrong,
        ),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: c.borderStrong,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.xl)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.xl),
        ),
        titleTextStyle: t.section,
        contentTextStyle: t.bodyMuted,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: c.ink,
        contentTextStyle: t.body.copyWith(color: c.background),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.control),
        ),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: c.primary,
        selectionColor: c.primary.withValues(alpha: 0.25),
        selectionHandleColor: c.primary,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: c.primary),
    );
  }

  static SystemUiOverlayStyle overlayStyle(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    return SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarContrastEnforced: false,
      statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
      statusBarBrightness: brightness,
      systemNavigationBarIconBrightness: dark
          ? Brightness.light
          : Brightness.dark,
    );
  }
}
