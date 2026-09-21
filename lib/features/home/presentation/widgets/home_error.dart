import 'package:flutter/material.dart';
import 'package:lapse/core/theme/theme.dart';
import 'package:lapse/core/widgets/widgets.dart';

class HomeError extends StatelessWidget {
  const HomeError({required this.onRetry, super.key});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final lapse = context.lapse;
    return Padding(
      padding: const EdgeInsets.all(Space.xxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.cloud_off_rounded,
            size: 40,
            color: lapse.colors.inkSubtle,
          ),
          const SizedBox(height: Space.md),
          Text(
            "Couldn't load your subscriptions",
            textAlign: TextAlign.center,
            style: lapse.text.section,
          ),
          const SizedBox(height: Space.sm),
          LapseButton(
            label: 'Retry',
            icon: Icons.refresh_rounded,
            variant: LapseButtonVariant.secondary,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}
