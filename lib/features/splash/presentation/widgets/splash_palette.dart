import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import 'package:lapse/core/theme/tokens/lapse_colors.dart';

@immutable
class SplashPalette {
  const SplashPalette({
    required this.primary,
    required this.primaryTint,
    required this.track,
    required this.ink,
    required this.inkMuted,
  });

  factory SplashPalette.of(LapseColors colors) => SplashPalette(
    primary: colors.primary,
    primaryTint: colors.primaryTint,
    track: colors.ringTrack,
    ink: colors.ink,
    inkMuted: colors.inkMuted,
  );

  final Color primary;
  final Color primaryTint;
  final Color track;
  final Color ink;
  final Color inkMuted;

  @override
  bool operator ==(Object other) =>
      other is SplashPalette &&
      other.primary == primary &&
      other.primaryTint == primaryTint &&
      other.track == track &&
      other.ink == ink &&
      other.inkMuted == inkMuted;

  @override
  int get hashCode => Object.hash(primary, primaryTint, track, ink, inkMuted);
}
