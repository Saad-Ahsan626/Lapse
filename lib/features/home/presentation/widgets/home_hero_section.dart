import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lapse/features/home/presentation/widgets/home_hero_card.dart';
import 'package:lapse/features/home/presentation/widgets/home_hero_placeholder.dart';
import 'package:lapse/features/subscriptions/presentation/providers/home_providers.dart';

class HomeHeroSection extends ConsumerWidget {
  const HomeHeroSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(
      spendingSummaryProvider.select((value) => value.value),
    );
    return switch (summary) {
      final value? => HomeHeroCard(summary: value),
      null => const HomeHeroPlaceholder(),
    };
  }
}
