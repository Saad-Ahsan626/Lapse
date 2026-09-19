import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:lapse/core/domain/currency_info.dart';
import 'package:lapse/core/theme/theme.dart';
import 'package:lapse/core/widgets/widgets.dart';
import 'package:lapse/features/subscriptions/domain/validation/subscription_field.dart';
import 'package:lapse/features/subscriptions/presentation/form/subscription_form_state.dart';

class PriceSection extends StatelessWidget {
  const PriceSection({
    required this.state,
    required this.controller,
    required this.onChanged,
    required this.onCurrencyTap,
    this.focusNode,
    super.key,
  });

  final SubscriptionFormState state;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onCurrencyTap;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final lapse = context.lapse;
    final info = currencyInfo(state.currency);

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
            errorText: state.errors[SubscriptionField.price],
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
