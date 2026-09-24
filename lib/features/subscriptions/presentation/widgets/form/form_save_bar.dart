import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lapse/core/theme/theme.dart';
import 'package:lapse/core/widgets/widgets.dart';
import 'package:lapse/features/subscriptions/presentation/form/subscription_form_args.dart';
import 'package:lapse/features/subscriptions/presentation/form/subscription_form_controller.dart';

class FormSaveBar extends ConsumerWidget {
  const FormSaveBar({required this.args, required this.onSave, super.key});

  final SubscriptionFormArgs args;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (:canSave, :isSaving) = ref.watch(
      subscriptionFormProvider(
        args,
      ).select((s) => (canSave: s.canSave, isSaving: s.isSaving)),
    );
    return ColoredBox(
      color: context.lapse.colors.background,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            Space.xl,
            14,
            Space.xl,
            Space.md,
          ),
          child: LapseButton(
            label: 'Save',
            expand: true,
            loading: isSaving,
            onPressed: canSave ? onSave : null,
          ),
        ),
      ),
    );
  }
}
