import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lapse/core/motion/motion.dart';
import 'package:lapse/core/providers/clock_providers.dart';
import 'package:lapse/core/widgets/widgets.dart';
import 'package:lapse/features/savings/domain/cancellation_stats.dart';
import 'package:lapse/features/savings/domain/celebration_copy.dart';
import 'package:lapse/features/savings/presentation/celebration_result.dart';
import 'package:lapse/features/savings/presentation/widgets/celebration_sheet.dart';
import 'package:lapse/features/subscriptions/domain/entities/subscription.dart';
import 'package:lapse/features/subscriptions/presentation/providers/subscription_service_providers.dart';

Future<void> markCancelledWithCelebration(
  BuildContext context,
  WidgetRef ref,
  Subscription subscription,
) async {
  final messenger = ScaffoldMessenger.of(context);
  final navigator = Navigator.of(context);
  final view = View.of(context);
  final direction = Directionality.of(context);
  final reduce = reduceMotion(context);
  final markCancelled = ref.read(markCancelledProvider);
  final restore = ref.read(restoreSubscriptionProvider);
  final repository = ref.read(subscriptionRepositoryProvider);
  final clock = ref.read(clockProvider);

  final saved = await markCancelled(subscription.id);
  final all = await repository.getAll();
  final count = CancellationStats.cancelledThisYear(all, clock());
  if (!navigator.mounted) return;

  if (!reduce) unawaited(HapticFeedback.mediumImpact());
  unawaited(
    SemanticsService.sendAnnouncement(
      view,
      CelebrationCopy.announcement(subscription, saved),
      direction,
    ),
  );

  final result = await showLapseSheet<CelebrationResult>(
    context: navigator.context,
    showClose: false,
    builder: (_) => CelebrationSheet(
      headline: CelebrationCopy.headline(subscription),
      saved: saved,
      body: CelebrationCopy.body(subscription, cancelledThisYear: count),
      playConfetti: !reduce,
    ),
  );
  if (result != CelebrationResult.undo) return;

  await restore(subscription.id);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text('${subscription.name} restored')));
}
