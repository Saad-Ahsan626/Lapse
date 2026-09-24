import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lapse/app/app_ready_controller.dart';
import 'package:lapse/app/router/routes.dart';
import 'package:lapse/core/motion/motion.dart';
import 'package:lapse/core/theme/theme.dart';
import 'package:lapse/features/settings/presentation/providers/settings_providers.dart';
import 'package:lapse/features/splash/presentation/splash_clock.dart';
import 'package:lapse/features/splash/presentation/splash_timeline.dart';
import 'package:lapse/features/splash/presentation/widgets/splash_painter.dart';
import 'package:lapse/features/splash/presentation/widgets/splash_palette.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _progress = AnimationController(vsync: this);
  late final Ticker _ticker = createTicker(_onTick);

  SplashTimeline? _timeline;
  SplashClock? _clock;
  SplashPainter? _painter;
  bool _navigated = false;
  late final AppReadyController _appReady;

  @override
  void initState() {
    super.initState();
    _appReady = ref.read(appReadyProvider.notifier);
    unawaited(_startAfterFirstFrame());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final timeline = _timeline ??= _createTimeline();
    final lapse = context.lapse;
    final palette = SplashPalette.of(lapse.colors);
    final dpr = MediaQuery.devicePixelRatioOf(context);
    const wordmarkStyle = TextStyle(
      fontFamily: LapseTypography.fontFamily,
      fontWeight: FontWeight.w800,
      letterSpacing: -SplashPainter.defaultLogoSize * 0.3 * 1.4 / 40,
    );
    final taglineStyle = lapse.text.meta.copyWith(fontWeight: FontWeight.w600);
    final current = _painter;
    if (current != null &&
        current.palette == palette &&
        current.devicePixelRatio == dpr &&
        current.wordmarkStyle == wordmarkStyle &&
        current.taglineStyle == taglineStyle) {
      return;
    }
    current?.dispose();
    _painter = SplashPainter(
      progress: _progress,
      timeline: timeline,
      palette: palette,
      wordmarkStyle: wordmarkStyle,
      taglineStyle: taglineStyle,
      devicePixelRatio: dpr,
    );
  }

  SplashTimeline _createTimeline() {
    final timeline = SplashTimeline.forLaunch(
      onboardingDone: ref.read(settingsProvider).onboardingDone,
      reduceMotion: reduceMotion(context),
    );
    _clock = SplashClock(duration: timeline.duration);
    return timeline;
  }

  Future<void> _startAfterFirstFrame() async {
    await SchedulerBinding.instance.endOfFrame;
    if (!mounted) return;
    _painter?.warmUp();
    await SchedulerBinding.instance.endOfFrame;
    if (!mounted) return;
    unawaited(_ticker.start());
  }

  void _onTick(Duration elapsed) {
    final clock = _clock;
    if (clock == null) return;
    _progress.value = clock.tick(elapsed);
    if (clock.isDone) _finish();
  }

  void _finish() {
    _ticker.stop();
    if (_navigated || !mounted) return;
    _navigated = true;
    _appReady.markReady();
    final done = ref.read(settingsProvider).onboardingDone;
    context.go(done ? Routes.home : Routes.onboarding);
  }

  @override
  void dispose() {
    if (!_navigated) scheduleMicrotask(_appReady.markReady);
    _ticker.dispose();
    _progress.dispose();
    _painter?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.lapse.colors.background,
      body: Semantics(
        label: 'Lapse',
        image: true,
        excludeSemantics: true,
        child: RepaintBoundary(
          child: CustomPaint(
            key: const ValueKey('splash-canvas'),
            painter: _painter,
            size: Size.infinite,
          ),
        ),
      ),
    );
  }
}
