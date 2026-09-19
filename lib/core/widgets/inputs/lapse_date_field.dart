import 'dart:async';

import 'package:flutter/material.dart';

import 'package:lapse/core/domain/calendar_date.dart';
import 'package:lapse/core/theme/lapse_theme.dart';
import 'package:lapse/core/theme/tokens/lapse_spacing.dart';

class LapseDateField extends StatelessWidget {
  const LapseDateField({
    required this.value,
    required this.onChanged,
    required this.format,
    this.label,
    this.firstDate,
    this.lastDate,
    this.trailing,
    this.errorText,
    super.key,
  });

  static const placeholder = 'Pick a date';

  final CalendarDate? value;
  final ValueChanged<CalendarDate> onChanged;
  final String Function(CalendarDate) format;
  final String? label;
  final CalendarDate? firstDate;
  final CalendarDate? lastDate;
  final Widget? trailing;
  final String? errorText;

  Future<void> _pick(BuildContext context) async {
    final today = CalendarDate.fromDateTime(DateTime.now());
    var initial = value ?? today;
    final first = firstDate ?? initial.addMonths(-120);
    final last = lastDate ?? initial.addMonths(120);
    if (initial.isBefore(first)) initial = first;
    if (initial.isAfter(last)) initial = last;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial.toDateTime(),
      firstDate: first.toDateTime(),
      lastDate: last.toDateTime(),
      helpText: label,
    );
    if (picked != null) onChanged(CalendarDate.fromDateTime(picked));
  }

  @override
  Widget build(BuildContext context) {
    final lapse = context.lapse;
    final c = lapse.colors;
    final hasError = errorText != null;
    final current = value;
    final shown = current == null ? placeholder : format(current);
    final borderRadius = BorderRadius.circular(Radii.control);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          ExcludeSemantics(
            child: Text(label!.toUpperCase(), style: lapse.text.caption),
          ),
          const SizedBox(height: Space.sm),
        ],
        Semantics(
          button: true,
          label: label == null ? shown : '$label, $shown',
          excludeSemantics: true,
          onTap: () => unawaited(_pick(context)),
          child: Material(
            color: c.surface,
            shape: RoundedRectangleBorder(
              borderRadius: borderRadius,
              side: BorderSide(
                color: hasError
                    ? c.urgent.withValues(alpha: 0.5)
                    : c.inputBorder,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => unawaited(_pick(context)),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: Sizes.input),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: Space.sm,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          shown,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: current == null
                              ? lapse.text.itemTitle.copyWith(
                                  color: c.inkSubtle,
                                )
                              : lapse.text.itemTitle,
                        ),
                      ),
                      if (trailing != null) ...[
                        const SizedBox(width: Space.sm),
                        trailing!,
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.error_outline_rounded, size: 15, color: c.urgentText),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  errorText!,
                  style: lapse.text.meta.copyWith(color: c.urgentText),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
