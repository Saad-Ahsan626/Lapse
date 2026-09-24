import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lapse/app/router/routes.dart';
import 'package:lapse/core/motion/motion.dart';
import 'package:lapse/core/theme/theme.dart';
import 'package:lapse/core/widgets/widgets.dart';
import 'package:lapse/features/onboarding/domain/onboarding_slide.dart';
import 'package:lapse/features/onboarding/presentation/widgets/illustrations/cancel_illustration.dart';
import 'package:lapse/features/onboarding/presentation/widgets/illustrations/charge_illustration.dart';
import 'package:lapse/features/onboarding/presentation/widgets/illustrations/reminder_illustration.dart';
import 'package:lapse/features/onboarding/presentation/widgets/parallax_slide.dart';
import 'package:lapse/features/onboarding/presentation/widgets/worm_indicator.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _controller = PageController();
  final ValueNotifier<int> _pageIndex = ValueNotifier<int>(0);
  final List<OnboardingSlide> _slides = OnboardingSlide.all;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_syncIndex);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_syncIndex)
      ..dispose();
    _pageIndex.dispose();
    super.dispose();
  }

  void _syncIndex() => _pageIndex.value = ParallaxSlide.pageOf(
    _controller,
  ).round().clamp(0, _slides.length - 1);

  int get _index => _pageIndex.value;

  bool _isLastIndex(int index) => index == _slides.length - 1;

  void _goTo(int index) {
    if (reduceMotion(context)) {
      _controller.jumpToPage(index);
    } else {
      unawaited(
        _controller.animateToPage(
          index,
          duration: Motion.hero,
          curve: Motion.emphasized,
        ),
      );
    }
  }

  void _next() {
    if (_isLastIndex(_index)) {
      _finish();
    } else {
      _goTo(_index + 1);
    }
  }

  void _finish() {
    unawaited(context.push(Routes.setup));
  }

  Widget _illustrationFor(OnboardingIllustration kind) => switch (kind) {
    OnboardingIllustration.charge => const ChargeIllustration(),
    OnboardingIllustration.reminder => const ReminderIllustration(),
    OnboardingIllustration.cancel => const CancelIllustration(),
  };

  @override
  Widget build(BuildContext context) {
    final lapse = context.lapse;
    final c = lapse.colors;

    final scaffold = Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Space.screen,
                Space.sm,
                Space.sm,
                0,
              ),
              child: Align(
                alignment: Alignment.centerRight,
                child: ValueListenableBuilder<int>(
                  valueListenable: _pageIndex,
                  builder: (context, index, _) => _isLastIndex(index)
                      ? const SizedBox(height: Sizes.button)
                      : LapseButton(
                          label: 'Skip',
                          variant: LapseButtonVariant.text,
                          foregroundColor: c.inkSubtle,
                          onPressed: _finish,
                        ),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _slides.length,
                itemBuilder: (context, i) {
                  final slide = _slides[i];
                  return ParallaxSlide(
                    controller: _controller,
                    index: i,
                    illustration: _illustrationFor(slide.illustration),
                    text: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Space.xxxl + Space.md,
                      ),
                      child: Column(
                        children: [
                          Semantics(
                            header: true,
                            child: Text(
                              slide.title,
                              style: lapse.text.title,
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: Space.md),
                          Text(
                            slide.body,
                            style: lapse.text.bodyMuted,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: Space.lg),
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) => WormIndicator(
                page: ParallaxSlide.pageOf(_controller),
                count: _slides.length,
              ),
            ),
            const SizedBox(height: Space.xxl),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Space.screen,
                0,
                Space.screen,
                Space.lg,
              ),
              child: SizedBox(
                width: double.infinity,
                child: ValueListenableBuilder<int>(
                  valueListenable: _pageIndex,
                  builder: (context, index, _) => LapseButton(
                    label: _isLastIndex(index) ? 'Get started' : 'Next',
                    expand: true,
                    onPressed: _next,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return ValueListenableBuilder<int>(
      valueListenable: _pageIndex,
      child: scaffold,
      builder: (context, index, child) => PopScope(
        canPop: index == 0,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop && index > 0) _goTo(index - 1);
        },
        child: child!,
      ),
    );
  }
}
