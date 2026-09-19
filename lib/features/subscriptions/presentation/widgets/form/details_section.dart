import 'dart:async';

import 'package:flutter/material.dart';

import 'package:lapse/core/theme/theme.dart';
import 'package:lapse/core/widgets/widgets.dart';
import 'package:lapse/features/subscriptions/domain/validation/subscription_field.dart';
import 'package:lapse/features/subscriptions/presentation/form/subscription_form_state.dart';

class DetailsSection extends StatelessWidget {
  const DetailsSection({
    required this.state,
    required this.cancelUrlController,
    required this.paymentMethodController,
    required this.notesController,
    required this.onCancelUrlChanged,
    required this.onCategoryChanged,
    required this.onPaymentMethodChanged,
    required this.onNotesChanged,
    super.key,
  });

  static const categories = [
    'Entertainment',
    'Music',
    'Productivity',
    'AI',
    'Storage',
    'Design',
    'Developer',
    'Education',
    'Health',
    'Gaming',
    'Security',
    'News & reading',
    'Other',
  ];

  final SubscriptionFormState state;
  final TextEditingController cancelUrlController;
  final TextEditingController paymentMethodController;
  final TextEditingController notesController;
  final ValueChanged<String> onCancelUrlChanged;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<String> onPaymentMethodChanged;
  final ValueChanged<String> onNotesChanged;

  Future<void> _pickCategory(BuildContext context) async {
    final options = [
      ...categories,
      if (state.category != null && !categories.contains(state.category))
        state.category!,
    ];
    final picked = await showLapseSheet<String>(
      context: context,
      title: 'Category',
      builder: (sheetContext) {
        final lapse = sheetContext.lapse;
        final c = lapse.colors;
        return ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.only(bottom: Space.xl),
          children: [
            for (final option in options)
              Semantics(
                button: true,
                selected: option == state.category,
                label: option,
                excludeSemantics: true,
                onTap: () => Navigator.of(sheetContext).pop(option),
                child: InkWell(
                  onTap: () => Navigator.of(sheetContext).pop(option),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 52),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Space.screen,
                        vertical: Space.sm,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(option, style: lapse.text.itemTitle),
                          ),
                          if (option == state.category)
                            Icon(
                              Icons.check_rounded,
                              size: 22,
                              color: c.primary,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
    if (picked != null) onCategoryChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    return LapseRowGroup(
      children: [
        LapseRowField(
          label: 'Cancel link',
          controller: cancelUrlController,
          hint: 'https://',
          keyboardType: TextInputType.url,
          textInputAction: TextInputAction.next,
          errorText: state.errors[SubscriptionField.cancelUrl],
          onChanged: onCancelUrlChanged,
        ),
        LapseRowField(
          label: 'Category',
          value: state.category,
          hint: 'Choose',
          trailing: const Icon(Icons.keyboard_arrow_down_rounded),
          onTap: () => unawaited(_pickCategory(context)),
        ),
        LapseRowField(
          label: 'Payment method',
          controller: paymentMethodController,
          hint: 'e.g. HBL ···· 4417',
          textInputAction: TextInputAction.next,
          errorText: state.errors[SubscriptionField.paymentMethod],
          onChanged: onPaymentMethodChanged,
        ),
        LapseRowField(
          label: 'Notes',
          controller: notesController,
          hint: 'Optional',
          maxLines: 4,
          onChanged: onNotesChanged,
        ),
      ],
    );
  }
}
