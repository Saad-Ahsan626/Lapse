import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lapse/core/theme/theme.dart';
import 'package:lapse/core/widgets/widgets.dart';
import 'package:lapse/features/savings/presentation/widgets/savings_summary_card.dart';
import 'package:lapse/features/subscriptions/domain/entities/subscription.dart';
import 'package:lapse/features/subscriptions/presentation/providers/subscription_list_providers.dart';
import 'package:lapse/features/subscriptions/presentation/providers/subscription_tab.dart';
import 'package:lapse/features/subscriptions/presentation/providers/subscription_tab_providers.dart';
import 'package:lapse/features/subscriptions/presentation/widgets/list/empty_tab.dart';
import 'package:lapse/features/subscriptions/presentation/widgets/list/subscription_row.dart';
import 'package:lapse/features/subscriptions/presentation/widgets/list/swipe_hint.dart';

class SubscriptionsTabView extends ConsumerStatefulWidget {
  const SubscriptionsTabView({
    required this.tab,
    required this.onOpen,
    required this.onAdd,
    super.key,
  });

  final SubscriptionTab tab;
  final ValueChanged<Subscription> onOpen;
  final VoidCallback onAdd;

  static const int skeletonCount = 4;
  static const double gap = 10;
  static const EdgeInsets padding = EdgeInsets.symmetric(
    horizontal: Space.screen,
  );

  @override
  ConsumerState<SubscriptionsTabView> createState() =>
      _SubscriptionsTabViewState();
}

class _SubscriptionsTabViewState extends ConsumerState<SubscriptionsTabView> {
  final Set<SubscriptionTab> _entered = {};

  void _markEntered(SubscriptionTab tab) {
    if (_entered.contains(tab)) return;
    WidgetsBinding.instance.addPostFrameCallback((_) => _entered.add(tab));
  }

  @override
  Widget build(BuildContext context) {
    final tab = widget.tab;
    final items = ref.watch(subscriptionTabProvider(tab));
    if (items.hasValue) _markEntered(tab);
    return switch (items) {
      AsyncValue(:final value?) when value.isEmpty => SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: Space.xxl),
            child: EmptyTab(tab: tab, onAdd: widget.onAdd),
          ),
        ),
      ),
      AsyncValue(:final value?) => SliverMainAxisGroup(
        slivers: [
          if (tab == SubscriptionTab.cancelled)
            const SliverPadding(
              padding: EdgeInsets.fromLTRB(
                Space.screen,
                0,
                Space.screen,
                Space.md,
              ),
              sliver: SliverToBoxAdapter(child: SavingsSummaryCard()),
            ),
          SliverPadding(
            padding: SubscriptionsTabView.padding,
            sliver: SliverList.separated(
              itemCount: value.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: SubscriptionsTabView.gap),
              itemBuilder: (context, index) {
                final subscription = value[index];
                return StaggeredEntrance(
                  key: ValueKey(subscription.id),
                  index: index,
                  animate:
                      !_entered.contains(tab) &&
                      index < StaggeredEntrance.maxSteps,
                  child: SubscriptionRow(
                    key: ValueKey(subscription.id),
                    subscription: subscription,
                    onTap: () => widget.onOpen(subscription),
                  ),
                );
              },
            ),
          ),
          SliverToBoxAdapter(child: SwipeHint(tab: tab)),
        ],
      ),
      AsyncValue(:final error?) => SliverFillRemaining(
        hasScrollBody: false,
        child: _ErrorView(
          error: error,
          onRetry: () => ref.invalidate(subscriptionsProvider),
        ),
      ),
      _ => SliverPadding(
        padding: SubscriptionsTabView.padding,
        sliver: SliverList.separated(
          itemCount: SubscriptionsTabView.skeletonCount,
          separatorBuilder: (_, _) =>
              const SizedBox(height: SubscriptionsTabView.gap),
          itemBuilder: (_, _) => const SkeletonRow(),
        ),
      ),
    };
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final text = context.lapse.text;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Space.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Couldn’t load your subscriptions',
              style: text.section,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Space.sm),
            Text(
              '$error',
              style: text.bodyMuted,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: Space.lg),
            LapseButton(
              label: 'Retry',
              variant: LapseButtonVariant.secondary,
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}
