import 'package:flutter/material.dart';

import 'package:lapse/core/domain/urgency.dart';
import 'package:lapse/core/theme/theme.dart';
import 'package:lapse/core/widgets/widgets.dart';
import 'package:lapse/features/debug/presentation/widgets/gallery_section.dart';

class ChipsSection extends StatefulWidget {
  const ChipsSection({super.key});

  @override
  State<ChipsSection> createState() => _ChipsSectionState();
}

class _ChipsSectionState extends State<ChipsSection> {
  static const _cycles = ['Weekly', 'Monthly', 'Quarterly', 'Yearly', 'Custom'];
  static const _reminders = ['7 days', '3 days', '1 day', 'Same day'];

  String _cycle = 'Monthly';
  final Set<String> _remind = {'7 days', '1 day'};

  void _toggleReminder(String r) =>
      setState(() => _remind.contains(r) ? _remind.remove(r) : _remind.add(r));

  @override
  Widget build(BuildContext context) {
    return GallerySection(
      title: 'Chips',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 9,
            children: [
              for (final cycle in _cycles)
                LapseChip(
                  label: cycle,
                  selected: _cycle == cycle,
                  onTap: () => setState(() => _cycle = cycle),
                ),
            ],
          ),
          Wrap(
            spacing: 9,
            children: [
              for (final r in _reminders)
                LapseChip(
                  label: r,
                  showCheck: true,
                  selected: _remind.contains(r),
                  onTap: () => _toggleReminder(r),
                ),
            ],
          ),
          const SizedBox(height: Space.md),
          const Wrap(
            spacing: 9,
            runSpacing: 9,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              UrgencyChip(label: 'Tomorrow', urgency: Urgency.urgent),
              UrgencyChip(label: 'In 3 days', urgency: Urgency.warning),
              UrgencyChip(label: 'Oct 24', urgency: Urgency.normal),
              TrialBadge(),
              SavingsPill(
                label: 'Saved Rs 7,788 🎉',
                semanticLabel: 'Saved Rs 7,788',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
