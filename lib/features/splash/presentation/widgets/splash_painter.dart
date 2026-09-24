import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/animation.dart';
import 'package:flutter/rendering.dart';

import 'package:lapse/core/theme/tokens/lapse_spacing.dart';
import 'package:lapse/core/widgets/rings/ring_geometry.dart';
import 'package:lapse/features/splash/presentation/splash_timeline.dart';
import 'package:lapse/features/splash/presentation/widgets/splash_palette.dart';

class SplashPainter extends CustomPainter {
  SplashPainter({
    required Animation<double> progress,
    required this.timeline,
    required this.palette,
    required this.wordmarkStyle,
    required this.taglineStyle,
    required this.devicePixelRatio,
    this.logoSize = defaultLogoSize,
  }) : _progress = progress,
       super(repaint: progress);

  static const double defaultLogoSize = 96;
  static const double _unit = 48;
  static const double _radiusUnits = 19;
  static const double _strokeUnits = 5;
  static const List<Offset> _checkUnits = [
    Offset(16, 24.6),
    Offset(21.6, 30.2),
    Offset(32, 19),
  ];

  final Animation<double> _progress;
  final SplashTimeline timeline;
  final SplashPalette palette;
  final TextStyle wordmarkStyle;
  final TextStyle taglineStyle;
  final double devicePixelRatio;
  final double logoSize;

  double get _scaleUnit => logoSize / _unit;
  double get _radius => _radiusUnits * _scaleUnit;
  double get _stroke => _strokeUnits * _scaleUnit;
  double get _wordmarkHeight => logoSize * 0.3;
  double get _taglineHeight => logoSize * 0.16;

  late final Rect _ringRect = Rect.fromCircle(
    center: Offset.zero,
    radius: _radius,
  );

  late final Paint _strokePaint = RingGeometry.stroke(palette.primary, _stroke)
    ..strokeJoin = StrokeJoin.round;
  late final Paint _trackPaint = RingGeometry.stroke(palette.track, _stroke);
  late final Paint _ripplePaint = Paint()..style = PaintingStyle.stroke;
  late final Paint _fillPaint = Paint();
  late final Paint _imagePaint = Paint()..filterQuality = FilterQuality.medium;

  late final double _backgroundRadius = logoSize * 1.5;
  late final Shader _backgroundShader = _radial(
    palette.primaryTint,
    _backgroundRadius,
  );
  late final double _bloomRadius = logoSize * 0.65;
  late final Shader _bloomShader = _radial(
    palette.primary.withValues(alpha: 0.38),
    _bloomRadius,
  );
  late final double _headRadius = _stroke * 2.2;
  late final Shader _headShader = _radial(
    palette.primary.withValues(alpha: 0.55),
    _headRadius,
  );

  late final Path _checkPath = _buildCheckPath();
  late final ui.PathMetric _checkMetric = _checkPath.computeMetrics().first;

  late final _TextLayer _layer = _TextLayer.build(
    wordmark: SplashTimeline.wordmark,
    wordmarkStyle: wordmarkStyle.copyWith(
      fontSize: _wordmarkHeight,
      height: 1,
      color: palette.ink,
    ),
    tagline: SplashTimeline.tagline,
    taglineStyle: taglineStyle.copyWith(
      fontSize: _taglineHeight,
      height: 1,
      color: palette.inkMuted,
    ),
    devicePixelRatio: devicePixelRatio,
  );

  static const Size _warmUpSize = Size(360, 640);

  bool _disposed = false;
  bool _warm = false;

  bool get isDisposed => _disposed;

  bool get isWarm => _warm;

  static Shader _radial(Color color, double radius) => ui.Gradient.radial(
    Offset.zero,
    radius,
    [color, color.withValues(alpha: 0)],
  );

  Path _buildCheckPath() {
    final unit = _scaleUnit;
    final half = logoSize / 2;
    Offset point(Offset units) =>
        Offset(units.dx * unit - half, units.dy * unit - half);
    return Path()
      ..moveTo(point(_checkUnits[0]).dx, point(_checkUnits[0]).dy)
      ..lineTo(point(_checkUnits[1]).dx, point(_checkUnits[1]).dy)
      ..lineTo(point(_checkUnits[2]).dx, point(_checkUnits[2]).dy);
  }

  double get elapsedMs => _progress.value * timeline.durationMs;

  void warmUp() {
    if (_disposed || _warm) return;
    _warm = true;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    for (final ms in timeline.warmUpMoments) {
      _paintAt(canvas, _warmUpSize, ms);
    }
    recorder.endRecording().dispose();
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (_disposed) return;
    _paintAt(canvas, size, elapsedMs);
  }

  void _paintAt(Canvas canvas, Size size, double ms) {
    final alpha = timeline.opacity(ms);
    if (alpha <= 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    canvas
      ..save()
      ..translate(center.dx, center.dy);
    final scale = timeline.logoScale(ms);
    if (scale != 1) canvas.scale(scale);
    _paintLogo(canvas, ms, alpha);
    canvas.restore();

    _paintText(canvas, center, ms, alpha);
  }

  void _paintLogo(Canvas canvas, double ms, double alpha) {
    _paintGlow(
      canvas,
      _backgroundShader,
      _backgroundRadius,
      timeline.backgroundGlow(ms) * alpha,
    );
    _paintGlow(
      canvas,
      _bloomShader,
      _bloomRadius,
      timeline.glowOpacity(ms) * alpha,
    );

    final track = timeline.trackOpacity(ms) * alpha;
    if (track > 0) {
      _trackPaint.color = palette.track.withValues(
        alpha: palette.track.a * track,
      );
      canvas.drawCircle(Offset.zero, _radius, _trackPaint);
    }

    final ripple = timeline.rippleProgress(ms);
    if (ripple != null) {
      _ripplePaint
        ..strokeWidth = (3 - 2 * ripple) * _scaleUnit * 2
        ..color = palette.primary.withValues(
          alpha: 0.35 * (1 - ripple) * alpha,
        );
      canvas.drawCircle(
        Offset.zero,
        _radius + (logoSize * 0.62 - _radius) * ripple,
        _ripplePaint,
      );
    }

    final arcFraction = timeline.arcFraction(ms);
    final start =
        RingGeometry.startAngle(RingGeometry.logoGapFraction) +
        timeline.arcRotation(ms);
    final sweep = 2 * math.pi * arcFraction;

    final head = timeline.headGlow(ms) * alpha;
    if (head > 0) {
      final angle = start + sweep;
      canvas
        ..save()
        ..translate(math.cos(angle) * _radius, math.sin(angle) * _radius);
      _paintGlow(canvas, _headShader, _headRadius, head);
      canvas.restore();
    }

    _strokePaint.color = palette.primary.withValues(alpha: alpha);
    if (arcFraction > 0) {
      canvas.drawArc(_ringRect, start, sweep, false, _strokePaint);
    }

    final check = timeline.checkProgress(ms);
    if (check >= 1) {
      canvas.drawPath(_checkPath, _strokePaint);
    } else if (check > 0) {
      canvas.drawPath(
        _checkMetric.extractPath(0, _checkMetric.length * check),
        _strokePaint,
      );
    }
  }

  void _paintGlow(Canvas canvas, Shader shader, double radius, double alpha) {
    if (alpha <= 0) return;
    _fillPaint
      ..shader = shader
      ..color = Color.fromRGBO(0, 0, 0, alpha.clamp(0, 1));
    canvas.drawCircle(Offset.zero, radius, _fillPaint);
  }

  void _paintText(Canvas canvas, Offset center, double ms, double alpha) {
    final layer = _layer;
    final wordTop = center.dy + logoSize / 2 + Space.lg;
    final wordLeft = center.dx - layer.wordWidth / 2;
    for (var i = 0; i < layer.letters.length; i++) {
      final letter = layer.letters[i];
      _paintImage(
        canvas,
        letter.image,
        Offset(
          wordLeft + letter.left - letter.pad,
          wordTop + timeline.letterOffset(i, ms) - letter.pad,
        ),
        letter.size,
        timeline.letterProgress(i, ms) * alpha,
      );
    }
    final tagline = layer.tagline;
    _paintImage(
      canvas,
      tagline.image,
      Offset(
        center.dx - tagline.size.width / 2,
        wordTop + _wordmarkHeight + Space.sm - tagline.pad,
      ),
      tagline.size,
      timeline.taglineOpacity(ms) * alpha,
    );
  }

  void _paintImage(
    Canvas canvas,
    ui.Image image,
    Offset topLeft,
    Size size,
    double alpha,
  ) {
    if (alpha <= 0) return;
    _imagePaint.color = Color.fromRGBO(0, 0, 0, alpha.clamp(0, 1));
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      topLeft & size,
      _imagePaint,
    );
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _layer.dispose();
  }

  @override
  bool shouldRepaint(SplashPainter oldDelegate) =>
      oldDelegate._progress != _progress ||
      oldDelegate.timeline.duration != timeline.duration ||
      oldDelegate.palette != palette ||
      oldDelegate.wordmarkStyle != wordmarkStyle ||
      oldDelegate.taglineStyle != taglineStyle ||
      oldDelegate.devicePixelRatio != devicePixelRatio ||
      oldDelegate.logoSize != logoSize;

  @override
  bool? hitTest(Offset position) => false;
}

class _Glyph {
  _Glyph(this.image, this.size, this.left, this.pad);

  final ui.Image image;
  final Size size;
  final double left;
  final double pad;
}

class _TextLayer {
  _TextLayer(this.letters, this.wordWidth, this.tagline);

  factory _TextLayer.build({
    required String wordmark,
    required TextStyle wordmarkStyle,
    required String tagline,
    required TextStyle taglineStyle,
    required double devicePixelRatio,
  }) {
    final word = _layout(wordmark, wordmarkStyle);
    final letters = <_Glyph>[];
    for (var i = 0; i < wordmark.length; i++) {
      final boxes = word.getBoxesForSelection(
        TextSelection(baseOffset: i, extentOffset: i + 1),
      );
      final left = boxes.isEmpty ? 0.0 : boxes.first.left;
      final glyph = _layout(wordmark[i], wordmarkStyle);
      final pad = _padFor(wordmarkStyle);
      letters.add(
        _Glyph(
          _rasterize(glyph, devicePixelRatio, pad),
          _paddedSize(glyph, pad),
          left,
          pad,
        ),
      );
      glyph.dispose();
    }
    final wordWidth = word.width;
    word.dispose();
    final line = _layout(tagline, taglineStyle);
    final taglinePad = _padFor(taglineStyle);
    final taglineGlyph = _Glyph(
      _rasterize(line, devicePixelRatio, taglinePad),
      _paddedSize(line, taglinePad),
      0,
      taglinePad,
    );
    line.dispose();
    return _TextLayer(letters, wordWidth, taglineGlyph);
  }

  final List<_Glyph> letters;
  final double wordWidth;
  final _Glyph tagline;

  static TextPainter _layout(String text, TextStyle style) => TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
    maxLines: 1,
  )..layout();

  static double _padFor(TextStyle style) => (style.fontSize ?? 14) * 0.25;

  static Size _paddedSize(TextPainter painter, double pad) =>
      Size(painter.width + pad * 2, painter.height + pad * 2);

  static ui.Image _rasterize(
    TextPainter painter,
    double devicePixelRatio,
    double pad,
  ) {
    final size = _paddedSize(painter, pad);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)..scale(devicePixelRatio);
    painter.paint(canvas, Offset(pad, pad));
    final picture = recorder.endRecording();
    final image = picture.toImageSync(
      math.max(1, (size.width * devicePixelRatio).ceil()),
      math.max(1, (size.height * devicePixelRatio).ceil()),
    );
    picture.dispose();
    return image;
  }

  void dispose() {
    for (final letter in letters) {
      letter.image.dispose();
    }
    tagline.image.dispose();
  }
}
