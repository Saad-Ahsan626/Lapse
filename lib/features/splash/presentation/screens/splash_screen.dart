import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:lapse/app/router/routes.dart';
import 'package:lapse/core/motion/motion.dart';
import 'package:lapse/core/theme/theme.dart';
import 'package:lapse/features/settings/presentation/providers/settings_providers.dart';
import 'package:lapse/features/splash/presentation/splash_timeline.dart';
import 'package:lapse/features/splash/presentation/widgets/animated_logo.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
  )..addStatusListener(_onStatus);

  SplashTimeline? _timeline;
  bool _navigated = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_timeline != null) return;
    final timeline = SplashTimeline.forLaunch(
      onboardingDone: ref.read(settingsProvider).onboardingDone,
      reduceMotion: reduceMotion(context),
    );
    _timeline = timeline;
    _controller.duration = timeline.duration;
    unawaited(_controller.forward());
  }

  void _onStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    if (_navigated || !mounted) return;
    _navigated = true;
    final done = ref.read(settingsProvider).onboardingDone;
    context.go(done ? Routes.home : Routes.onboarding);
  }

  @override
  void dispose() {
    _controller
      ..removeStatusListener(_onStatus)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final timeline = _timeline!;
    return Scaffold(
      backgroundColor: context.lapse.colors.background,
      body: Semantics(
        label: 'Lapse',
        image: true,
        excludeSemantics: true,
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => AnimatedLogo(
              timeline: timeline,
              elapsedMs: _controller.value * timeline.durationMs,
            ),
          ),
        ),
      ),
    );
  }
}
