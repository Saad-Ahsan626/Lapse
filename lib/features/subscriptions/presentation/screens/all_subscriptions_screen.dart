import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:lapse/app/router/routes.dart';
import 'package:lapse/core/theme/theme.dart';
import 'package:lapse/core/widgets/widgets.dart';
import 'package:lapse/features/subscriptions/domain/entities/subscription.dart';
import 'package:lapse/features/subscriptions/presentation/providers/subscription_tab.dart';
import 'package:lapse/features/subscriptions/presentation/providers/subscription_tab_providers.dart';
import 'package:lapse/features/subscriptions/presentation/widgets/list/subscriptions_tab_view.dart';
import 'package:lapse/features/subscriptions/presentation/widgets/list/subscriptions_top_bar.dart';

class AllSubscriptionsScreen extends ConsumerStatefulWidget {
  const AllSubscriptionsScreen({
    this.initialTab = SubscriptionTab.active,
    super.key,
  });

  final SubscriptionTab initialTab;

  @override
  ConsumerState<AllSubscriptionsScreen> createState() =>
      _AllSubscriptionsScreenState();
}

class _AllSubscriptionsScreenState
    extends ConsumerState<AllSubscriptionsScreen> {
  late SubscriptionTab _tab = widget.initialTab;

  @override
  void didUpdateWidget(AllSubscriptionsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTab != widget.initialTab) {
      _tab = widget.initialTab;
    }
  }

  void _select(SubscriptionTab tab) {
    if (tab == _tab) return;
    setState(() => _tab = tab);
  }

  void _open(Subscription subscription) =>
      unawaited(context.push(Routes.detail(subscription.id)));

  void _add() => unawaited(context.push(Routes.newSubscription));

  @override
  Widget build(BuildContext context) {
    final c = context.lapse.colors;
    final counts = ref.watch(subscriptionTabCountsProvider).value;
    final canPop = Navigator.of(context).canPop();

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        bottom: false,
        child: SwipeActionsGroup(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: SubscriptionsTopBar(
                  onBack: canPop
                      ? () => Navigator.of(context).maybePop()
                      : null,
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  Space.screen,
                  0,
                  Space.screen,
                  Space.lg,
                ),
                sliver: SliverToBoxAdapter(
                  child: SegmentedTabs<SubscriptionTab>(
                    tabs: [
                      SegmentedTab(
                        value: SubscriptionTab.active,
                        label: 'Active',
                        count: counts?.active,
                      ),
                      SegmentedTab(
                        value: SubscriptionTab.trials,
                        label: 'Trials',
                        count: counts?.trials,
                      ),
                      SegmentedTab(
                        value: SubscriptionTab.cancelled,
                        label: 'Cancelled',
                        count: counts?.cancelled,
                      ),
                    ],
                    selected: _tab,
                    onChanged: _select,
                  ),
                ),
              ),
              SubscriptionsTabView(tab: _tab, onOpen: _open, onAdd: _add),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: MediaQuery.paddingOf(context).bottom + Space.xxl,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
