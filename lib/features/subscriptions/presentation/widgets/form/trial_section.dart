import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lapse/features/subscriptions/domain/validation/subscription_field.dart';
import 'package:lapse/features/subscriptions/presentation/form/subscription_form_args.dart';
import 'package:lapse/features/subscriptions/presentation/form/subscription_form_controller.dart';
import 'package:lapse/features/subscriptions/presentation/widgets/form/trial_block.dart';

class TrialSection extends ConsumerWidget {
  const TrialSection({
    required this.args,
    required this.priceController,
    required this.onCurrencyTap,
    super.key,
  });

  final SubscriptionFormArgs args;
  final TextEditingController priceController;
  final VoidCallback onCurrencyTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = subscriptionFormProvider(args);
    final (:isTrial, :length, :currency, :error) = ref.watch(
      provider.select(
        (s) => (
          isTrial: s.isTrial,
          length: s.trialLengthDays,
          currency: s.currency,
          error: s.errors[SubscriptionField.price],
        ),
      ),
    );
    final notifier = ref.read(provider.notifier);
    return TrialBlock(
      isTrial: isTrial,
      trialLengthDays: length,
      currency: currency,
      priceError: error,
      priceController: priceController,
      onTrialChanged: (on) => notifier.setTrial(on: on),
      onTrialLengthChanged: notifier.setTrialLength,
      onPriceChanged: notifier.setPrice,
      onCurrencyTap: onCurrencyTap,
    );
  }
}
