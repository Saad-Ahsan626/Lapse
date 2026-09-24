import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lapse/core/theme/theme.dart';
import 'package:lapse/features/catalog/presentation/catalog_picker.dart';
import 'package:lapse/features/home/presentation/widgets/home_add_fab.dart';
import 'package:lapse/features/home/presentation/widgets/home_empty_state.dart';
import 'package:lapse/features/home/presentation/widgets/home_error.dart';
import 'package:lapse/features/home/presentation/widgets/home_header.dart';
import 'package:lapse/features/home/presentation/widgets/home_hero_section.dart';
import 'package:lapse/features/home/presentation/widgets/home_loading.dart';
import 'package:lapse/features/home/presentation/widgets/home_trials_section.dart';
import 'package:lapse/features/home/presentation/widgets/home_upcoming_section.dart';
import 'package:lapse/features/reminders/presentation/widgets/reminders_off_banner.dart';
import 'package:lapse/features/subscriptions/presentation/providers/home_providers.dart';
import 'package:lapse/features/subscriptions/presentation/providers/subscription_list_providers.dart';

enum _HomePhase { loading, error, empty, populated }

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
    _pickerOpen = true;
    await showCatalogPicker(context);
    _pickerOpen = false;
  }

  void _add() => unawaited(_openPicker());

  void _retry() => ref.invalidate(subscriptionsProvider);

  @override
  Widget build(BuildContext context) {
    final phase = ref.watch(
      subscriptionsProvider.select(
        (value) => value.when(
          data: (all) => all.isEmpty ? _HomePhase.empty : _HomePhase.populated,
          loading: () => _HomePhase.loading,
          error: (_, _) => _HomePhase.error,
        ),
      ),
    );
    final populated = phase == _HomePhase.populated;
    final summaryFailed =
        populated &&
        ref.watch(spendingSummaryProvider.select((value) => value.hasError));

    final body = switch (phase) {
      _HomePhase.loading => const [SliverToBoxAdapter(child: HomeLoading())],
      _HomePhase.error => [_errorSliver()],
      _ => [
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
        if (!populated)
          _CenteredSliver(child: HomeEmptyState(onAdd: _add))
        else if (summaryFailed)
          _errorSliver()
        else
          ..._populatedSlivers,
      ],
    };

    return Scaffold(
      backgroundColor: context.lapse.colors.background,
      floatingActionButton: populated ? const HomeAddFab() : null,
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

  static const List<Widget> _populatedSlivers = [
    SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: Space.screen),
      sliver: SliverToBoxAdapter(child: HomeHeroSection()),
    ),
    SliverToBoxAdapter(child: SizedBox(height: HomeScreen.sectionGap)),
    SliverToBoxAdapter(
      child: HomeTrialsSection(gap: HomeScreen.sectionGap),
    ),
    SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: Space.screen),
      sliver: SliverToBoxAdapter(child: HomeUpcomingSection()),
    ),
    SliverToBoxAdapter(child: _FabClearance()),
  ];
}

class _FabClearance extends StatelessWidget {
  const _FabClearance();

  @override
  Widget build(BuildContext context) => SizedBox(
    height: Sizes.fab + Space.xxxl + MediaQuery.paddingOf(context).bottom,
  );
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
