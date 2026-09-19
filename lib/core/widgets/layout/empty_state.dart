import 'package:flutter/material.dart';

import 'package:lapse/core/theme/lapse_theme.dart';
import 'package:lapse/core/theme/tokens/lapse_spacing.dart';
import 'package:lapse/core/widgets/buttons/lapse_button.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.illustration,
    required this.title,
    required this.message,
    this.primaryLabel,
    this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
    super.key,
  });

  final Widget illustration;
  final String title;
  final String message;
  final String? primaryLabel;
  final VoidCallback? onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    final text = context.lapse.text;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Space.xxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          illustration,
          const SizedBox(height: Space.xxl),
          Text(
            title,
            style: text.title.copyWith(fontSize: 21),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Space.sm),
          Text(message, style: text.bodyMuted, textAlign: TextAlign.center),
          if (primaryLabel != null) ...[
            const SizedBox(height: Space.xxl),
            LapseButton(
              label: primaryLabel!,
              onPressed: onPrimary,
              expand: true,
            ),
          ],
          if (secondaryLabel != null) ...[
            const SizedBox(height: Space.xs),
            LapseButton(
              label: secondaryLabel!,
              onPressed: onSecondary,
              variant: LapseButtonVariant.text,
            ),
          ],
        ],
      ),
    );
  }
}
