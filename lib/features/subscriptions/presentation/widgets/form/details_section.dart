import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lapse/core/theme/theme.dart';
import 'package:lapse/core/widgets/widgets.dart';
import 'package:lapse/features/subscriptions/domain/validation/subscription_field.dart';
import 'package:lapse/features/subscriptions/presentation/form/subscription_form_args.dart';
import 'package:lapse/features/subscriptions/presentation/form/subscription_form_controller.dart';

class DetailsSection extends ConsumerWidget {
  const DetailsSection({
    required this.args,
    required this.cancelUrlController,
    required this.paymentMethodController,
    required this.notesController,
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

  final SubscriptionFormArgs args;
  final TextEditingController cancelUrlController;
  final TextEditingController paymentMethodController;
  final TextEditingController notesController;

  Future<void> _pickCategory(
    BuildContext context,
    String? current,
    ValueChanged<String> onPicked,
  ) async {
    final options = [
      ...categories,
      if (current != null && !categories.contains(current)) current,
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
                selected: option == current,
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
                          if (option == current)
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
    if (picked != null) onPicked(picked);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = subscriptionFormProvider(args);
    final (:category, :cancelUrlError, :paymentError) = ref.watch(
      provider.select(
        (s) => (
          category: s.category,
          cancelUrlError: s.errors[SubscriptionField.cancelUrl],
          paymentError: s.errors[SubscriptionField.paymentMethod],
        ),
      ),
    );
    final notifier = ref.read(provider.notifier);
    return LapseRowGroup(
      children: [
        LapseRowField(
          label: 'Cancel link',
          controller: cancelUrlController,
          hint: 'https://',
          keyboardType: TextInputType.url,
          textInputAction: TextInputAction.next,
          errorText: cancelUrlError,
          onChanged: notifier.setCancelUrl,
        ),
        LapseRowField(
          label: 'Category',
          value: category,
          hint: 'Choose',
          trailing: const Icon(Icons.keyboard_arrow_down_rounded),
          onTap: () => unawaited(
            _pickCategory(context, category, notifier.setCategory),
          ),
        ),
        LapseRowField(
          label: 'Payment method',
          controller: paymentMethodController,
          hint: 'e.g. HBL ···· 4417',
          textInputAction: TextInputAction.next,
          errorText: paymentError,
          onChanged: notifier.setPaymentMethod,
        ),
        LapseRowField(
          label: 'Notes',
          controller: notesController,
          hint: 'Optional',
          maxLines: 4,
          onChanged: notifier.setNotes,
        ),
      ],
    );
  }
}
