import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lapse/core/providers/clock_providers.dart';
import 'package:lapse/core/theme/theme.dart';
import 'package:lapse/core/widgets/widgets.dart';
import 'package:lapse/features/catalog/presentation/catalog_picker.dart';
import 'package:lapse/features/home/presentation/widgets/home_empty_state.dart';
import 'package:lapse/features/home/presentation/widgets/home_error.dart';
import 'package:lapse/features/home/presentation/widgets/home_header.dart';
import 'package:lapse/features/home/presentation/widgets/home_hero_card.dart';
import 'package:lapse/features/home/presentation/widgets/home_hero_placeholder.dart';
import 'package:lapse/features/home/presentation/widgets/home_loading.dart';
import 'package:lapse/features/home/presentation/widgets/trials_strip.dart';
import 'package:lapse/features/home/presentation/widgets/upcoming_section.dart';
import 'package:lapse/features/reminders/presentation/widgets/reminders_off_banner.dart';
import 'package:lapse/features/subscriptions/presentation/providers/home_providers.dart';
import 'package:lapse/features/subscriptions/presentation/providers/subscription_list_providers.dart';
import 'package:lapse/features/subscriptions/presentation/providers/upcoming_charges.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  static const double sectionGap = 28;

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _pickerOpen = false;

  Future<void> _openPicker() async {
    if (_pickerOpen) return;
    setState(() => _pickerOpen = true);
    await showCatalogPicker(context);
    if (mounted) setState(() => _pickerOpen = false);
  }

  void _add() => unawaited(_openPicker());

  void _retry() => ref.invalidate(subscriptionsProvider);

  @override
  Widget build(BuildContext context) {
    final subscriptions = ref.watch(subscriptionsProvider);
    final populated =
        !subscriptions.hasError && (subscriptions.value?.isNotEmpty ?? false);

    final body = subscriptions.when(
      data: (all) => [
        const SliverToBoxAdapter(
          child: RemindersOffBanner(
            padding: EdgeInsets.fromLTRB(
              Space.screen,
              0,
              Space.screen,
              Space.xl,
            ),
          ),
        ),
        if (all.isEmpty)
          _CenteredSliver(child: HomeEmptyState(onAdd: _add))
        else
          ..._populatedSlivers(),
      ],
      loading: () => const [SliverToBoxAdapter(child: HomeLoading())],
      error: (_, _) => [_errorSliver()],
    );

    return Scaffold(
      backgroundColor: context.lapse.colors.background,
      floatingActionButton: populated
          ? LapseFab(open: _pickerOpen, onPressed: _add)
          : null,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(child: HomeHeader()),
            ...body,
          ],
        ),
      ),
    );
  }

  Widget _errorSliver() => _CenteredSliver(child: HomeError(onRetry: _retry));

  List<Widget> _populatedSlivers() {
    final summary = ref.watch(spendingSummaryProvider);
    if (summary.hasError) return [_errorSliver()];
    final today = ref.watch(todayProvider);
    final trials = ref.watch(trialsEndingProvider).value ?? const [];
    final upcoming =
        ref.watch(upcomingChargesProvider).value ??
        const UpcomingCharges(items: [], isThisMonth: false);
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return [
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: Space.screen),
        sliver: SliverToBoxAdapter(
          child: switch (summary.value) {
            final value? => HomeHeroCard(summary: value),
            null => const HomeHeroPlaceholder(),
          },
        ),
      ),
      const SliverToBoxAdapter(child: SizedBox(height: HomeScreen.sectionGap)),
      if (trials.isNotEmpty) ...[
        SliverToBoxAdapter(
          child: TrialsStrip(trials: trials, today: today),
        ),
        const SliverToBoxAdapter(
          child: SizedBox(height: HomeScreen.sectionGap),
        ),
      ],
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: Space.screen),
        sliver: SliverToBoxAdapter(
          child: UpcomingSection(
            upcoming: upcoming,
            today: today,
            hasTrials: trials.isNotEmpty,
          ),
        ),
      ),
      SliverToBoxAdapter(
        child: SizedBox(height: Sizes.fab + Space.xxxl + bottomInset),
      ),
    ];
  }
}

class _CenteredSliver extends StatelessWidget {
  const _CenteredSliver({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final remaining = math
            .max(
              0,
              constraints.viewportMainAxisExtent -
                  constraints.precedingScrollExtent,
            )
            .toDouble();
        return SliverToBoxAdapter(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: remaining),
            child: Center(child: child),
          ),
        );
      },
    );
  }
}
