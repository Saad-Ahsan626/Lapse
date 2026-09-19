import 'dart:async';

import 'package:flutter/material.dart';

import 'package:lapse/core/theme/lapse_theme.dart';
import 'package:lapse/core/theme/tokens/lapse_spacing.dart';
import 'package:lapse/core/widgets/layout/lapse_bottom_sheet.dart';

class LapseSelectField<T> extends StatelessWidget {
  const LapseSelectField({
    required this.value,
    required this.options,
    required this.labelOf,
    required this.onChanged,
    this.label,
    this.hint,
    this.sheetTitle,
    this.errorText,
    super.key,
  });

  final T? value;
  final List<T> options;
  final String Function(T) labelOf;
  final ValueChanged<T> onChanged;
  final String? label;
  final String? hint;
  final String? sheetTitle;
  final String? errorText;

  Future<void> _open(BuildContext context) async {
    final picked = await showLapseSheet<T>(
      context: context,
      title: sheetTitle ?? label,
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
                selected: option == value,
                label: labelOf(option),
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
                            child: Text(
                              labelOf(option),
                              style: lapse.text.itemTitle,
                            ),
                          ),
                          if (option == value)
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
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final lapse = context.lapse;
    final c = lapse.colors;
    final hasError = errorText != null;
    final current = value;
    final shown = current == null ? (hint ?? '') : labelOf(current);
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
          onTap: () => unawaited(_open(context)),
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
              onTap: () => unawaited(_open(context)),
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
                      const SizedBox(width: Space.sm),
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 22,
                        color: c.inkSubtle,
                      ),
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
