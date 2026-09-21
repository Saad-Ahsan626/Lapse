import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lapse/core/theme/theme.dart';
import 'package:lapse/core/widgets/widgets.dart';
import 'package:lapse/features/subscriptions/domain/entities/subscription.dart';
import 'package:lapse/features/subscriptions/presentation/providers/subscription_service_providers.dart';

Future<void> restoreWithFeedback(
  BuildContext context,
  WidgetRef ref,
  Subscription subscription,
) async {
  final messenger = ScaffoldMessenger.of(context);
  await ref.read(restoreSubscriptionProvider)(subscription.id);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text('${subscription.name} restored')));
}

Future<bool> confirmAndDelete(
  BuildContext context,
  WidgetRef ref,
  Subscription subscription,
) async {
  final messenger = ScaffoldMessenger.of(context);
  final delete = ref.read(deleteSubscriptionProvider);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => _DeleteDialog(name: subscription.name),
  );
  if (confirmed != true) return false;
  await delete(subscription.id);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text('${subscription.name} deleted')));
  return true;
}

class _DeleteDialog extends StatelessWidget {
  const _DeleteDialog({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Delete $name?'),
      content: Text(
        'Its payment history is deleted too. This cannot be undone.',
        style: context.lapse.text.bodyMuted,
      ),
      actionsPadding: const EdgeInsets.fromLTRB(
        Space.lg,
        0,
        Space.lg,
        Space.lg,
      ),
      actions: [
        LapseButton(
          label: 'Keep',
          variant: LapseButtonVariant.text,
          onPressed: () => Navigator.of(context).pop(false),
        ),
        LapseButton(
          label: 'Delete',
          variant: LapseButtonVariant.danger,
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    );
  }
}
