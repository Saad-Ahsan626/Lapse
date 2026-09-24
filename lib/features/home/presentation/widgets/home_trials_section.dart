import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lapse/core/providers/clock_providers.dart';
import 'package:lapse/features/home/presentation/providers/home_section_providers.dart';
import 'package:lapse/features/home/presentation/widgets/trials_strip.dart';

class HomeTrialsSection extends ConsumerWidget {
  const HomeTrialsSection({required this.gap, super.key});

  final double gap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trials = ref.watch(homeTrialsProvider);
    if (trials.isEmpty) return const SizedBox.shrink();
    final today = ref.watch(todayProvider);
    return Padding(
      padding: EdgeInsets.only(bottom: gap),
      child: TrialsStrip(trials: trials.items, today: today),
    );
  }
}
