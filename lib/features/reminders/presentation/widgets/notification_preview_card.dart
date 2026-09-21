import 'package:flutter/material.dart';
import 'package:lapse/core/theme/theme.dart';
import 'package:lapse/core/widgets/widgets.dart';

class NotificationPreviewCard extends StatelessWidget {
  const NotificationPreviewCard({
    this.message = sampleMessage,
    this.time = 'now',
    super.key,
  });

  static const sampleMessage =
      "⚠️ Your Netflix trial ends tomorrow — you'll be charged Rs 649. "
      'Tap to cancel.';

  static const double _tile = 36;

  final String message;
  final String time;

  @override
  Widget build(BuildContext context) {
    final lapse = context.lapse;
    final c = lapse.colors;
    final radius = BorderRadius.circular(Radii.card);

    return Semantics(
      container: true,
      label: 'Example notification',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: radius,
          border: Border.all(color: c.border),
          boxShadow: c.cardShadow,
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ExcludeSemantics(
                child: Container(
                  width: _tile,
                  height: _tile,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: c.primary,
                    borderRadius: BorderRadius.circular(Radii.tile(_tile)),
                  ),
                  child: LogoMark(size: _tile * 0.72, color: c.onPrimary),
                ),
              ),
              const SizedBox(width: Space.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text('Lapse', style: lapse.text.itemTitle),
                        ),
                        const SizedBox(width: Space.sm),
                        Text(time, style: lapse.text.meta),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(message, style: lapse.text.body),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
