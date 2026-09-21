import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lapse/core/widgets/brand/lapse_logo_painter.dart';
import 'package:lapse/features/splash/presentation/splash_timeline.dart';
import 'package:lapse/features/splash/presentation/widgets/animated_logo.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  const full = SplashTimeline.full();

  LapseLogoPainter painterOf(WidgetTester tester) => tester
      .widgetList<CustomPaint>(find.byType(CustomPaint))
      .map((paint) => paint.painter)
      .whereType<LapseLogoPainter>()
      .single;

  testWidgets('drives the painter from the timeline', (tester) async {
    await tester.pumpLapse(
      const AnimatedLogo(timeline: full, elapsedMs: 1250),
    );

    final painter = painterOf(tester);
    expect(painter.checkProgress, full.checkProgress(1250));
    expect(painter.arcFraction, full.arcFraction(1250));
    expect(painter.rotation, full.arcRotation(1250));
    expect(find.byKey(const ValueKey('splash-glow')), findsOneWidget);
  });

  testWidgets('keeps the mark centred and the wordmark below', (
    tester,
  ) async {
    await tester.pumpLapse(
      const AnimatedLogo(timeline: full, elapsedMs: 1600),
    );

    final logo = tester.getCenter(
      find.byWidgetPredicate(
        (widget) => widget is CustomPaint && widget.painter is LapseLogoPainter,
      ),
    );
    final screen = tester.getCenter(find.byType(Scaffold));
    expect(logo.dx, closeTo(screen.dx, 0.5));
    expect(logo.dy, closeTo(screen.dy, 0.5));
    expect(tester.getCenter(find.text('Lapse')).dy, greaterThan(logo.dy));
    expect(find.byKey(const ValueKey('splash-glow')), findsNothing);
  });

  testWidgets('renders in dark mode at text scale 2', (tester) async {
    await tester.pumpLapse(
      const AnimatedLogo(timeline: SplashTimeline.reduced(), elapsedMs: 0),
      brightness: Brightness.dark,
      textScale: 2,
    );

    expect(tester.takeException(), isNull);
    expect(painterOf(tester).color, const Color(0xFF818CF8));
  });
}
