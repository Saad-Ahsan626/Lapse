import 'package:flutter/material.dart';

import 'package:lapse/core/theme/theme.dart';
import 'package:lapse/core/widgets/widgets.dart';

class SettingsGroup extends StatelessWidget {
  const SettingsGroup({
    required this.label,
    required this.children,
    this.footer,
    super.key,
  });

  final String label;
  final List<Widget> children;
  final String? footer;

  @override
  Widget build(BuildContext context) {
    final lapse = context.lapse;
    final note = footer;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Space.xs),
          child: Semantics(
            container: true,
            header: true,
            child: Text(label.toUpperCase(), style: lapse.text.caption),
          ),
        ),
        const SizedBox(height: Space.sm),
        LapseRowGroup(children: children),
        if (note != null) ...[
          const SizedBox(height: Space.sm),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.xs),
            child: Text(note, style: lapse.text.meta),
          ),
        ],
      ],
    );
  }
}
