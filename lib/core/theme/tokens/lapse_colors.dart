import 'package:flutter/material.dart';

import 'package:lapse/core/domain/urgency.dart';

@immutable
class LapseColors {
  const LapseColors({
    required this.brightness,
    required this.primary,
    required this.onPrimary,
    required this.primaryTint,
    required this.savings,
    required this.savingsText,
    required this.savingsTint,
    required this.trial,
    required this.onTrial,
    required this.urgent,
    required this.urgentText,
    required this.urgentTint,
    required this.warning,
    required this.warningText,
    required this.warningTint,
    required this.dangerText,
    required this.dangerTint,
    required this.background,
    required this.surface,
    required this.surfaceMuted,
    required this.onSurfaceMuted,
    required this.tile,
    required this.inputFill,
    required this.ink,
    required this.inkMuted,
    required this.inkSubtle,
    required this.border,
    required this.inputBorder,
    required this.borderStrong,
    required this.ringTrack,
    required this.heroGradient,
    required this.cardShadow,
    required this.raisedShadow,
    required this.heroShadow,
  });

  static const LapseColors light = LapseColors(
    brightness: Brightness.light,
    primary: Color(0xFF4F46E5),
    onPrimary: Color(0xFFFFFFFF),
    primaryTint: Color(0x1F4F46E5),
    savings: Color(0xFF10B981),
    savingsText: Color(0xFF047857),
    savingsTint: Color(0x2410B981),
    trial: Color(0xFF8B5CF6),
    onTrial: Color(0xFFFFFFFF),
    urgent: Color(0xFFEF4444),
    urgentText: Color(0xFFB42318),
    urgentTint: Color(0x1FEF4444),
    warning: Color(0xFFF59E0B),
    warningText: Color(0xFF92600A),
    warningTint: Color(0x24F59E0B),
    dangerText: Color(0xFFB91C1C),
    dangerTint: Color(0x1AEF4444),
    background: Color(0xFFFAFAFC),
    surface: Color(0xFFFFFFFF),
    surfaceMuted: Color(0xFFF1F1F6),
    onSurfaceMuted: Color(0xFF3A3A4C),
    tile: Color(0xFFECECF2),
    inputFill: Color(0xFFF7F7FA),
    ink: Color(0xFF12121A),
    inkMuted: Color(0xFF5A5A6E),
    inkSubtle: Color(0xFF8A8A9E),
    border: Color(0x1212121A),
    inputBorder: Color(0x1712121A),
    borderStrong: Color(0x2412121A),
    ringTrack: Color(0xFFF1F1F6),
    heroGradient: LinearGradient(
      begin: _gradientBegin,
      end: _gradientEnd,
      colors: [Color(0xFF4F46E5), Color(0xFF6366F1), Color(0xFF7C6CF5)],
      stops: [0, 0.55, 1],
    ),
    cardShadow: [
      BoxShadow(color: Color(0x0A12121A), blurRadius: 8, offset: Offset(0, 2)),
    ],
    raisedShadow: [
      BoxShadow(
        color: Color(0x1F12121A),
        blurRadius: 26,
        offset: Offset(0, 10),
      ),
    ],
    heroShadow: [
      BoxShadow(
        color: Color(0x4D4F46E5),
        blurRadius: 30,
        offset: Offset(0, 14),
      ),
    ],
  );

  static const LapseColors dark = LapseColors(
    brightness: Brightness.dark,
    primary: Color(0xFF818CF8),
    onPrimary: Color(0xFF0B0B12),
    primaryTint: Color(0x29818CF8),
    savings: Color(0xFF10B981),
    savingsText: Color(0xFF6EE7B7),
    savingsTint: Color(0x2E10B981),
    trial: Color(0xFF8B5CF6),
    onTrial: Color(0xFFFFFFFF),
    urgent: Color(0xFFEF4444),
    urgentText: Color(0xFFFCA5A5),
    urgentTint: Color(0x33EF4444),
    warning: Color(0xFFF59E0B),
    warningText: Color(0xFFFCD34D),
    warningTint: Color(0x2EF59E0B),
    dangerText: Color(0xFFFCA5A5),
    dangerTint: Color(0x29EF4444),
    background: Color(0xFF0B0B12),
    surface: Color(0xFF16161F),
    surfaceMuted: Color(0xFF1E1E2A),
    onSurfaceMuted: Color(0xFFD2D2E0),
    tile: Color(0xFF22222E),
    inputFill: Color(0xFF1E1E2A),
    ink: Color(0xFFF4F4F8),
    inkMuted: Color(0xFFA0A0B4),
    inkSubtle: Color(0xFF8A8AA3),
    border: Color(0x14FFFFFF),
    inputBorder: Color(0x17FFFFFF),
    borderStrong: Color(0x24FFFFFF),
    ringTrack: Color(0xFF22222E),
    heroGradient: LinearGradient(
      begin: _gradientBegin,
      end: _gradientEnd,
      colors: [Color(0xFF3F37C9), Color(0xFF4F46E5), Color(0xFF6D5EF0)],
      stops: [0, 0.55, 1],
    ),
    cardShadow: [],
    raisedShadow: [
      BoxShadow(
        color: Color(0x66000000),
        blurRadius: 44,
        offset: Offset(0, 20),
      ),
    ],
    heroShadow: [],
  );

  static const _gradientBegin = Alignment(-0.574, -0.819);
  static const _gradientEnd = Alignment(0.574, 0.819);

  final Brightness brightness;

  final Color primary;
  final Color onPrimary;

  final Color primaryTint;

  final Color savings;
  final Color savingsText;
  final Color savingsTint;

  final Color trial;
  final Color onTrial;

  final Color urgent;
  final Color urgentText;
  final Color urgentTint;

  final Color warning;
  final Color warningText;
  final Color warningTint;

  final Color dangerText;
  final Color dangerTint;

  final Color background;
  final Color surface;

  final Color surfaceMuted;
  final Color onSurfaceMuted;

  final Color tile;
  final Color inputFill;

  final Color ink;
  final Color inkMuted;
  final Color inkSubtle;

  final Color border;
  final Color inputBorder;
  final Color borderStrong;

  final Color ringTrack;

  final LinearGradient heroGradient;
  final List<BoxShadow> cardShadow;
  final List<BoxShadow> raisedShadow;
  final List<BoxShadow> heroShadow;

  bool get isDark => brightness == Brightness.dark;

  Color urgencyAccent(Urgency urgency) => switch (urgency) {
    Urgency.urgent => urgent,
    Urgency.warning => warning,
    Urgency.normal => primary,
  };

  ({Color background, Color foreground, Color dot}) urgencyChip(
    Urgency urgency,
  ) => switch (urgency) {
    Urgency.urgent => (
      background: urgentTint,
      foreground: urgentText,
      dot: urgent,
    ),
    Urgency.warning => (
      background: warningTint,
      foreground: warningText,
      dot: warning,
    ),
    Urgency.normal => (
      background: surfaceMuted,
      foreground: inkMuted,
      dot: inkSubtle,
    ),
  };

  LapseColors lerp(LapseColors other, double t) {
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    return LapseColors(
      brightness: t < 0.5 ? brightness : other.brightness,
      primary: c(primary, other.primary),
      onPrimary: c(onPrimary, other.onPrimary),
      primaryTint: c(primaryTint, other.primaryTint),
      savings: c(savings, other.savings),
      savingsText: c(savingsText, other.savingsText),
      savingsTint: c(savingsTint, other.savingsTint),
      trial: c(trial, other.trial),
      onTrial: c(onTrial, other.onTrial),
      urgent: c(urgent, other.urgent),
      urgentText: c(urgentText, other.urgentText),
      urgentTint: c(urgentTint, other.urgentTint),
      warning: c(warning, other.warning),
      warningText: c(warningText, other.warningText),
      warningTint: c(warningTint, other.warningTint),
      dangerText: c(dangerText, other.dangerText),
      dangerTint: c(dangerTint, other.dangerTint),
      background: c(background, other.background),
      surface: c(surface, other.surface),
      surfaceMuted: c(surfaceMuted, other.surfaceMuted),
      onSurfaceMuted: c(onSurfaceMuted, other.onSurfaceMuted),
      tile: c(tile, other.tile),
      inputFill: c(inputFill, other.inputFill),
      ink: c(ink, other.ink),
      inkMuted: c(inkMuted, other.inkMuted),
      inkSubtle: c(inkSubtle, other.inkSubtle),
      border: c(border, other.border),
      inputBorder: c(inputBorder, other.inputBorder),
      borderStrong: c(borderStrong, other.borderStrong),
      ringTrack: c(ringTrack, other.ringTrack),
      heroGradient: LinearGradient.lerp(heroGradient, other.heroGradient, t)!,
      cardShadow: BoxShadow.lerpList(cardShadow, other.cardShadow, t)!,
      raisedShadow: BoxShadow.lerpList(raisedShadow, other.raisedShadow, t)!,
      heroShadow: BoxShadow.lerpList(heroShadow, other.heroShadow, t)!,
    );
  }
}
