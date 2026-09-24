import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lapse/core/providers/clock_providers.dart';
import 'package:lapse/features/home/presentation/providers/home_section_providers.dart';
import 'package:lapse/features/home/presentation/widgets/upcoming_section.dart';

class HomeUpcomingSection extends ConsumerWidget {
  const HomeUpcomingSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final upcoming = ref.watch(homeUpcomingProvider);
    final hasTrials = ref.watch(
      homeTrialsProvider.select((trials) => trials.isNotEmpty),
    );
    final today = ref.watch(todayProvider);
    return UpcomingSection(
      upcoming: upcoming,
      today: today,
      hasTrials: hasTrials,
    );
  }
}
