import 'dart:async';

import 'package:flutter/material.dart';

import 'package:lapse/core/domain/calendar_date.dart';
import 'package:lapse/core/theme/theme.dart';
import 'package:lapse/core/widgets/widgets.dart';
import 'package:lapse/features/debug/presentation/widgets/gallery_section.dart';

class FormControlsSection extends StatefulWidget {
  const FormControlsSection({super.key});

  @override
  State<FormControlsSection> createState() => _FormControlsSectionState();
}

class _FormControlsSectionState extends State<FormControlsSection> {
  static const _categories = [
    'Entertainment',
    'Music',
    'Productivity',
    'Cloud storage',
    'Fitness',
  ];
  static const _trialLengths = ['3d', '7d', '14d', '30d', 'Custom'];

  final _cancelLink = TextEditingController(text: 'netflix.com/cancelplan');
  final _notes = TextEditingController();

  bool _fabOpen = false;
  String? _category = 'Entertainment';
  CalendarDate? _date = CalendarDate(2026, 9, 19);
  String _trialLength = '7d';

  @override
  void dispose() {
    _cancelLink.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _pickCategory() {
    unawaited(
      showLapseSheet<String>(
        context: context,
        title: 'Category',
        builder: (sheetContext) => ListView(
          shrinkWrap: true,
          children: [
            for (final category in _categories)
              ListTile(
                title: Text(category),
                onTap: () => Navigator.of(sheetContext).pop(category),
              ),
          ],
        ),
      ).then((picked) {
        if (picked != null && mounted) setState(() => _category = picked);
      }),
    );
  }

  void _openSheet() {
    unawaited(
      showLapseSheet<void>(
        context: context,
        title: 'Add subscription',
        builder: (sheetContext) => Padding(
          padding: const EdgeInsets.fromLTRB(
            Space.screen,
            0,
            Space.screen,
            Space.xxxl,
          ),
          child: Text(
            'Sheet body goes here.',
            style: sheetContext.lapse.text.bodyMuted,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.lapse.colors;
    return GallerySection(
      title: 'Form controls',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              LapseFab(onPressed: () => setState(() => _fabOpen = !_fabOpen)),
              const SizedBox(width: Space.lg),
              Expanded(
                child: Text(
                  _fabOpen ? 'Open (tap to close)' : 'Closed (tap to open)',
                  style: context.lapse.text.bodyMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: Space.xl),
          LapseSelectField<String>(
            label: 'Category',
            hint: 'Choose a category',
            value: _category,
            options: _categories,
            labelOf: (v) => v,
            onChanged: (v) => setState(() => _category = v),
          ),
          const SizedBox(height: Space.md),
          LapseDateField(
            label: 'Next billing date',
            value: _date,
            format: (d) => d.toIso(),
            onChanged: (d) => setState(() => _date = d),
            trailing: Text(
              'Tomorrow',
              style: context.lapse.text.chip.copyWith(color: c.urgentText),
            ),
          ),
          const SizedBox(height: Space.md),
          LapseRowGroup(
            children: [
              LapseRowField(
                label: 'Cancel link',
                controller: _cancelLink,
                keyboardType: TextInputType.url,
              ),
              LapseRowField(
                label: 'Category',
                value: _category,
                hint: 'None',
                onTap: _pickCategory,
                trailing: const Icon(Icons.keyboard_arrow_down_rounded),
              ),
              LapseRowField(
                label: 'Notes',
                controller: _notes,
                hint: 'Anything to remember',
                maxLines: 4,
              ),
            ],
          ),
          const SizedBox(height: Space.md),
          DecoratedBox(
            decoration: BoxDecoration(
              color: c.trial.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(Radii.card),
              border: Border.all(color: c.trial.withValues(alpha: 0.22)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Wrap(
                spacing: Space.sm,
                children: [
                  for (final length in _trialLengths)
                    LapseChip(
                      label: length,
                      tone: LapseChipTone.trial,
                      onTint: true,
                      selected: _trialLength == length,
                      onTap: () => setState(() => _trialLength = length),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: Space.md),
          LapseButton(
            label: 'Open sheet',
            variant: LapseButtonVariant.secondary,
            onPressed: _openSheet,
          ),
        ],
      ),
    );
  }
}
