import 'package:flutter/material.dart';

import 'package:lapse/core/theme/tokens/lapse_colors.dart';

@immutable
class LapseTypography {
  const LapseTypography({
    required this.moneyHero,
    required this.title,
    required this.section,
    required this.itemTitle,
    required this.body,
    required this.bodyMuted,
    required this.meta,
    required this.button,
    required this.chip,
    required this.chipSmall,
    required this.caption,
    required this.badge,
  });

  factory LapseTypography.from(LapseColors c) {
    const base = TextStyle(fontFamily: fontFamily, height: 1.25);
    return LapseTypography(
      moneyHero: base.copyWith(
        fontSize: 40,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.2,
        height: 1.1,
        color: c.ink,
        fontFeatures: tabular,
      ),
      title: base.copyWith(
        fontSize: 25,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.625,
        color: c.ink,
      ),
      section: base.copyWith(
        fontSize: 16.5,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.25,
        color: c.ink,
      ),
      itemTitle: base.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: c.ink,
      ),
      body: base.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.45,
        color: c.ink,
      ),
      bodyMuted: base.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.45,
        color: c.inkMuted,
      ),
      meta: base.copyWith(
        fontSize: 12.5,
        fontWeight: FontWeight.w500,
        color: c.inkSubtle,
        fontFeatures: tabular,
      ),
      button: base.copyWith(fontSize: 15, fontWeight: FontWeight.w700),
      chip: base.copyWith(fontSize: 13.5, fontWeight: FontWeight.w600),
      chipSmall: base.copyWith(
        fontSize: 12.5,
        fontWeight: FontWeight.w700,
        fontFeatures: tabular,
      ),
      caption: base.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.88,
        color: c.inkSubtle,
      ),
      badge: base.copyWith(
        fontSize: 10.5,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.84,
      ),
    );
  }

  static const fontFamily = 'PlusJakartaSans';
  static const tabular = [FontFeature.tabularFigures()];

  final TextStyle moneyHero;

  final TextStyle title;

  final TextStyle section;

  final TextStyle itemTitle;

  final TextStyle body;
  final TextStyle bodyMuted;

  final TextStyle meta;

  final TextStyle button;

  final TextStyle chip;

  final TextStyle chipSmall;

  final TextStyle caption;

  final TextStyle badge;

  static TextStyle money(TextStyle style) =>
      style.copyWith(fontFeatures: tabular);

  LapseTypography lerp(LapseTypography other, double t) {
    TextStyle s(TextStyle a, TextStyle b) => TextStyle.lerp(a, b, t)!;
    return LapseTypography(
      moneyHero: s(moneyHero, other.moneyHero),
      title: s(title, other.title),
      section: s(section, other.section),
      itemTitle: s(itemTitle, other.itemTitle),
      body: s(body, other.body),
      bodyMuted: s(bodyMuted, other.bodyMuted),
      meta: s(meta, other.meta),
      button: s(button, other.button),
      chip: s(chip, other.chip),
      chipSmall: s(chipSmall, other.chipSmall),
      caption: s(caption, other.caption),
      badge: s(badge, other.badge),
    );
  }
}
