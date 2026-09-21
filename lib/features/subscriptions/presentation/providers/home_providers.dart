import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lapse/core/domain/calendar_date.dart';
import 'package:lapse/core/providers/clock_providers.dart';
import 'package:lapse/features/settings/presentation/providers/settings_providers.dart';
import 'package:lapse/features/subscriptions/domain/entities/charge.dart';
import 'package:lapse/features/subscriptions/domain/entities/subscription.dart';
import 'package:lapse/features/subscriptions/domain/services/spending_calculator.dart';
import 'package:lapse/features/subscriptions/domain/services/spending_summary.dart';
import 'package:lapse/features/subscriptions/presentation/providers/subscription_list_providers.dart';
import 'package:lapse/features/subscriptions/presentation/providers/subscription_service_providers.dart';
import 'package:lapse/features/subscriptions/presentation/providers/upcoming_charges.dart';

const _fallbackUpcomingCount = 3;

CalendarDate _monthStart(CalendarDate today) =>
    CalendarDate(today.year, today.month, 1);

CalendarDate _monthEnd(CalendarDate today) => CalendarDate(
  today.year,
  today.month,
  CalendarDate.daysInMonth(today.year, today.month),
);

int _bySoonest(Subscription a, Subscription b) {
  final byDate = a.nextBillingDate.compareTo(b.nextBillingDate);
  if (byDate != 0) return byDate;
  return a.name.toLowerCase().compareTo(b.name.toLowerCase());
}

final chargesThisMonthProvider = FutureProvider<List<Charge>>((ref) {
  ref.watch(subscriptionsProvider);
  final today = ref.watch(todayProvider);
  return ref
      .watch(subscriptionRepositoryProvider)
      .chargesBetween(_monthStart(today), _monthEnd(today));
});

final _spendingSummarySnapshotProvider = FutureProvider<SpendingSummary>((
  ref,
) async {
  final subscriptions = await ref.watch(subscriptionsProvider.future);
  final today = ref.watch(todayProvider);
  final currency = ref.watch(
    settingsProvider.select((settings) => settings.defaultCurrency),
  );
  final engine = ref.watch(billingEngineProvider);
  final charges = await ref
      .watch(subscriptionRepositoryProvider)
      .chargesBetween(_monthStart(today), _monthEnd(today));
  return SpendingCalculator(engine).summarize(
    subscriptions: subscriptions,
    chargesThisMonth: charges,
    today: today,
    currency: currency,
  );
});

final spendingSummaryProvider = Provider<AsyncValue<SpendingSummary>>(
  (ref) => ref.watch(_spendingSummarySnapshotProvider),
);

final upcomingChargesProvider = Provider<AsyncValue<UpcomingCharges>>((ref) {
  final today = ref.watch(todayProvider);
  return ref.watch(subscriptionsProvider).whenData((all) {
    final candidates = all.where((s) => s.isActive && !s.isTrial).toList()
      ..sort(_bySoonest);
    final monthEnd = _monthEnd(today);
    final thisMonth = candidates
        .where((s) => !s.nextBillingDate.isAfter(monthEnd))
        .toList();
    if (thisMonth.isNotEmpty) {
      return UpcomingCharges(
        items: List.unmodifiable(thisMonth),
        isThisMonth: true,
      );
    }
    return UpcomingCharges(
      items: List.unmodifiable(candidates.take(_fallbackUpcomingCount)),
      isThisMonth: false,
    );
  });
});

final trialsEndingProvider = Provider<AsyncValue<List<Subscription>>>(
  (ref) => ref
      .watch(subscriptionsProvider)
      .whenData(
        (all) => List<Subscription>.unmodifiable(
          all.where((s) => s.isActive && s.isTrial).toList()..sort(_bySoonest),
        ),
      ),
);
