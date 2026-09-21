import 'package:flutter/foundation.dart';

enum OnboardingIllustration { charge, reminder, cancel }

@immutable
class OnboardingSlide {
  const OnboardingSlide({
    required this.title,
    required this.body,
    required this.illustration,
  });

  static const List<OnboardingSlide> all = [
    OnboardingSlide(
      title: 'Free trials quietly turn into charges',
      body:
          'The average person forgets two of them a year. '
          'The bank never does.',
      illustration: OnboardingIllustration.charge,
    ),
    OnboardingSlide(
      title: 'We remind you before — not after',
      body: 'Nudges at 7, 3 and 1 day out, at a time you choose.',
      illustration: OnboardingIllustration.reminder,
    ),
    OnboardingSlide(
      title: 'Cancel in one tap',
      body:
          'We keep the cancel link for every service, '
          'so you never hunt for it.',
      illustration: OnboardingIllustration.cancel,
    ),
  ];

  final String title;
  final String body;
  final OnboardingIllustration illustration;
}
