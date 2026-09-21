import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lapse/core/theme/lapse_theme.dart';
import 'package:lapse/core/theme/tokens/lapse_colors.dart';
import 'package:lapse/core/theme/tokens/lapse_spacing.dart';
import 'package:lapse/core/theme/tokens/lapse_typography.dart';

class ServiceTile extends StatelessWidget {
  const ServiceTile({
    required this.name,
    this.initials,
    this.brandColor,
    this.logoAsset,
    this.size = Sizes.serviceTile,
    this.heroTag,
    super.key,
  });

  final String name;
  final String? initials;
  final Color? brandColor;

  final String? logoAsset;
  final double size;

  final Object? heroTag;

  static String initialsFor(String name) {
    final words = name
        .split(RegExp('[^A-Za-z0-9]+'))
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.isEmpty) return '?';
    if (words.length == 1) {
      final w = words.first;
      return (w.length >= 2 ? w.substring(0, 2) : w).toUpperCase();
    }
    return (words[0][0] + words[1][0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.lapse.colors;
    final radius = BorderRadius.circular(Radii.tile(size));

    final Widget content;
    final Color background;
    Border? border;

    if (logoAsset != null) {
      background = Colors.white;
      if (c.isDark) border = Border.all(color: c.border);
      final pad = size * 0.18;
      content = Padding(
        padding: EdgeInsets.all(pad),
        child: logoAsset!.endsWith('.svg')
            ? SvgPicture.asset(logoAsset!)
            : Image.asset(logoAsset!, fit: BoxFit.contain),
      );
    } else {
      final bg = brandColor ?? c.tile;
      background = bg;
      if (brandColor != null && c.isDark && bg.computeLuminance() < 0.03) {
        border = Border.all(color: c.borderStrong);
      }
      final fg = brandColor == null
          ? c.inkSubtle
          : (ThemeData.estimateBrightnessForColor(bg) == Brightness.dark
                ? Colors.white
                : LapseColors.light.ink);
      content = Center(
        child: Text(
          initials ?? initialsFor(name),
          textScaler: TextScaler.noScaling,
          style: TextStyle(
            fontFamily: LapseTypography.fontFamily,
            fontSize: size * 0.3,
            fontWeight: FontWeight.w700,
            color: fg,
          ),
        ),
      );
    }

    Widget tile = Semantics(
      label: name,
      image: true,
      excludeSemantics: true,
      child: Container(
        width: size,
        height: size,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: background,
          borderRadius: radius,
          border: border,
        ),
        child: content,
      ),
    );

    if (heroTag != null) {
      tile = Hero(
        tag: heroTag!,
        createRectTween: _rectTween,
        flightShuttleBuilder: _shuttle,
        child: tile,
      );
    }
    return tile;
  }

  static RectTween _rectTween(Rect? begin, Rect? end) =>
      RectTween(begin: begin, end: end);

  Widget _shuttle(
    BuildContext flightContext,
    Animation<double> animation,
    HeroFlightDirection direction,
    BuildContext fromHeroContext,
    BuildContext toHeroContext,
  ) => LayoutBuilder(
    builder: (context, constraints) => ServiceTile(
      name: name,
      initials: initials,
      brandColor: brandColor,
      logoAsset: logoAsset,
      size: constraints.biggest.shortestSide,
    ),
  );
}
