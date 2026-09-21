import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:lapse/app/router/routes.dart';
import 'package:lapse/core/theme/theme.dart';
import 'package:lapse/core/widgets/widgets.dart';
import 'package:lapse/features/subscriptions/domain/entities/subscription.dart';
import 'package:lapse/features/subscriptions/presentation/actions/subscription_actions.dart';
import 'package:lapse/features/subscriptions/presentation/links/cancel_links.dart';
import 'package:lapse/features/subscriptions/presentation/providers/link_opener_provider.dart';
import 'package:lapse/features/subscriptions/presentation/providers/subscription_detail.dart';
import 'package:lapse/features/subscriptions/presentation/providers/subscription_detail_providers.dart';
import 'package:lapse/features/subscriptions/presentation/providers/subscription_list_providers.dart';
import 'package:lapse/features/subscriptions/presentation/widgets/detail/detail_actions_bar.dart';
import 'package:lapse/features/subscriptions/presentation/widgets/detail/detail_identity.dart';
import 'package:lapse/features/subscriptions/presentation/widgets/detail/detail_info_card.dart';
import 'package:lapse/features/subscriptions/presentation/widgets/detail/detail_menu.dart';
import 'package:lapse/features/subscriptions/presentation/widgets/detail/detail_ring.dart';
import 'package:lapse/features/subscriptions/presentation/widgets/detail/detail_top_bar.dart';
import 'package:lapse/features/subscriptions/presentation/widgets/detail/missing_cancel_link_sheet.dart';

class SubscriptionDetailScreen extends ConsumerStatefulWidget {
  const SubscriptionDetailScreen({required this.id, super.key});

  final String id;

  @override
  ConsumerState<SubscriptionDetailScreen> createState() =>
      _SubscriptionDetailScreenState();
}

class _SubscriptionDetailScreenState
    extends ConsumerState<SubscriptionDetailScreen> {
  bool _deleting = false;
  bool _left = false;
  bool _goneHandled = false;

  void _back() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      unawaited(navigator.maybePop());
      return;
    }
    GoRouter.maybeOf(context)?.go(Routes.home);
  }

  void _edit() => unawaited(GoRouter.of(context).push(Routes.edit(widget.id)));

  void _retry() {
    ref
      ..invalidate(subscriptionByIdProvider(widget.id))
      ..invalidate(chargesProvider(widget.id));
  }

  void _leave() {
    if (_left || !mounted) return;
    final navigator = Navigator.of(context);
    if (!navigator.canPop()) return;
    _left = true;
    navigator.pop();
  }

  void _handleGone() {
    if (_goneHandled) return;
    _goneHandled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _left) return;
      final navigator = Navigator.of(context);
      if (!navigator.canPop()) return;
      if (!_deleting) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(content: Text('This subscription was deleted')),
          );
      }
      _leave();
    });
  }

  Future<void> _cancelNow(Subscription subscription) async {
    final uri = cancelUriFor(subscription);
    if (uri != null) {
      final opened = await ref.read(linkOpenerProvider).open(uri);
      if (opened) return;
    }
    if (!mounted) return;
    await _missingLink(subscription);
  }

  Future<void> _missingLink(Subscription subscription) async {
    final choice = await showMissingCancelLinkSheet(context);
    if (!mounted || choice == null) return;
    switch (choice) {
      case MissingCancelLinkChoice.addLink:
        _edit();
      case MissingCancelLinkChoice.search:
        await ref
            .read(linkOpenerProvider)
            .open(howToCancelSearchUri(subscription.name));
    }
  }

  Future<void> _delete(Subscription subscription) async {
    _deleting = true;
    final deleted = await confirmAndDelete(context, ref, subscription);
    if (!deleted) {
      _deleting = false;
      return;
    }
    _leave();
  }

  Future<void> _menu(Subscription subscription) async {
    final action = await showDetailMenu(
      context,
      name: subscription.name,
      isCancelled: subscription.isCancelled,
    );
    if (!mounted || action == null) return;
    switch (action) {
      case DetailMenuAction.restore:
        await restoreWithFeedback(context, ref, subscription);
      case DetailMenuAction.delete:
        await _delete(subscription);
    }
  }

  @override
  Widget build(BuildContext context) {
    final value = ref.watch(subscriptionDetailProvider(widget.id));
    final c = context.lapse.colors;

    final detail = value.value;
    final Widget body;
    if (value.hasValue && detail != null) {
      body = _content(detail);
    } else if (value.hasValue) {
      body = _gone();
    } else if (value.hasError) {
      body = _Message(
        onBack: _back,
        message: 'Could not load this subscription.',
        actionLabel: 'Try again',
        onAction: _retry,
      );
    } else {
      body = Column(
        children: [
          DetailTopBar(onBack: _back),
          const Expanded(
            child: Center(
              child: CircularProgressIndicator(
                semanticsLabel: 'Loading subscription',
              ),
            ),
          ),
        ],
      );
    }

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(bottom: false, child: body),
    );
  }

  Widget _gone() {
    _handleGone();
    return _Message(
      onBack: _back,
      message: 'This subscription no longer exists',
      actionLabel: 'Go back',
      onAction: _back,
    );
  }

  Widget _content(SubscriptionDetail detail) {
    final subscription = detail.subscription;
    return Column(
      children: [
        DetailTopBar(
          onBack: _back,
          onEdit: _edit,
          onMenu: () => unawaited(_menu(subscription)),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              Space.xl,
              Space.lg,
              Space.xl,
              Space.xxl,
            ),
            children: [
              Center(child: DetailRing(detail: detail)),
              const SizedBox(height: Space.xxl),
              DetailIdentity(detail: detail),
              const SizedBox(height: Space.xxl),
              DetailInfoCard(
                detail: detail,
                onOpenCancelLink: () => unawaited(_cancelNow(subscription)),
              ),
            ],
          ),
        ),
        DetailActionsBar(
          isCancelled: subscription.isCancelled,
          onCancelNow: () => unawaited(_cancelNow(subscription)),
          onMarkCancelled: () =>
              unawaited(markCancelledWithUndo(context, ref, subscription)),
          onRestore: () =>
              unawaited(restoreWithFeedback(context, ref, subscription)),
          onDelete: () => unawaited(_delete(subscription)),
        ),
      ],
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.onBack,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final VoidCallback onBack;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final text = context.lapse.text;
    return Column(
      children: [
        DetailTopBar(onBack: onBack),
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(Space.xxl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: text.section,
                  ),
                  const SizedBox(height: Space.lg),
                  LapseButton(label: actionLabel, onPressed: onAction),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
