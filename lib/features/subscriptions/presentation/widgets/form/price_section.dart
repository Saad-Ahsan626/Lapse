import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lapse/core/domain/currency_info.dart';
import 'package:lapse/core/theme/theme.dart';
import 'package:lapse/core/widgets/widgets.dart';
import 'package:lapse/features/subscriptions/domain/validation/subscription_field.dart';
import 'package:lapse/features/subscriptions/presentation/form/subscription_form_args.dart';
import 'package:lapse/features/subscriptions/presentation/form/subscription_form_controller.dart';

class PriceSection extends ConsumerWidget {
  const PriceSection({
    required this.args,
    required this.controller,
    required this.onCurrencyTap,
    this.focusNode,
    super.key,
  });

  final SubscriptionFormArgs args;
  final TextEditingController controller;
  final VoidCallback onCurrencyTap;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = subscriptionFormProvider(args);
    final (:isTrial, :currency, :error) = ref.watch(
      provider.select(
        (s) => (
          isTrial: s.isTrial,
          currency: s.currency,
          error: s.errors[SubscriptionField.price],
        ),
      ),
    );
    if (isTrial) return const SizedBox.shrink();
    final lapse = context.lapse;
    final info = currencyInfo(currency);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        ExcludeSemantics(child: Text('PRICE', style: lapse.text.caption)),
        const SizedBox(height: Space.sm),
        Semantics(
          label: 'Price in ${info.name}',
          child: LapseTextField(
            controller: controller,
            focusNode: focusNode,
            hint: '0',
            prefixText: info.symbol,
            suffixText: info.code,
            onSuffixTap: onCurrencyTap,
            suffixSemanticLabel: 'Currency, ${info.code}. Change currency',
            tabular: true,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
            ),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp('[0-9.,]')),
            ],
            textInputAction: TextInputAction.done,
            errorText: error,
            onChanged: ref.read(provider.notifier).setPrice,
          ),
        ),
        const SizedBox(height: Space.xl),
      ],
    );
  }
}
