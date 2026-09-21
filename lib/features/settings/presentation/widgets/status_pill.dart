import 'package:flutter/material.dart';

import 'package:lapse/core/theme/theme.dart';

enum StatusTone { ok, attention, neutral }

class StatusPill extends StatelessWidget {
  const StatusPill({required this.label, required this.tone, super.key});

  final String label;
  final StatusTone tone;

  @override
  Widget build(BuildContext context) {
    final lapse = context.lapse;
    final c = lapse.colors;
    final (Color background, Color foreground) = switch (tone) {
      StatusTone.ok => (c.savingsTint, c.savingsText),
      StatusTone.attention => (c.warningTint, c.warningText),
      StatusTone.neutral => (c.surfaceMuted, c.inkMuted),
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(Radii.badge),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Space.sm + 2,
          vertical: Space.xs,
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: lapse.text.chipSmall.copyWith(color: foreground),
        ),
      ),
    );
  }
}
