import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lapse/features/home/presentation/providers/trials_ending.dart';
import 'package:lapse/features/subscriptions/presentation/providers/home_providers.dart';
import 'package:lapse/features/subscriptions/presentation/providers/upcoming_charges.dart';

final homeTrialsProvider = Provider<TrialsEnding>((ref) {
  final trials = ref.watch(trialsEndingProvider).value;
  return trials == null ? TrialsEnding.empty : TrialsEnding(trials);
});

final homeUpcomingProvider = Provider<UpcomingCharges>(
  (ref) =>
      ref.watch(upcomingChargesProvider).value ??
      const UpcomingCharges(items: [], isThisMonth: false),
);
