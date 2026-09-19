import 'package:flutter/material.dart';
import 'package:lapse/core/theme/theme.dart';
import 'package:lapse/core/widgets/widgets.dart';

class CatalogLoadError extends StatelessWidget {
  const CatalogLoadError({required this.onRetry, super.key});

  static const message = 'Couldn’t load the service list.';

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final lapse = context.lapse;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Space.screen),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: lapse.text.bodyMuted,
            ),
            const SizedBox(height: Space.md),
            LapseButton(
              label: 'Retry',
              icon: Icons.refresh_rounded,
              variant: LapseButtonVariant.secondary,
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}
