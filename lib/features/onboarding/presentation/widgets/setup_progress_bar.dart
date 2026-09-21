import 'package:flutter/material.dart';

import 'package:lapse/core/theme/theme.dart';

class SetupProgressBar extends StatelessWidget {
  const SetupProgressBar({
    this.segments = 3,
    this.filled = 2,
    super.key,
  }) : assert(segments > 0, 'segments must be positive'),
       assert(
         filled >= 0 && filled <= segments,
         'filled must be within segments',
       );

  final int segments;
  final int filled;

  static const double height = 4;

  @override
  Widget build(BuildContext context) {
    final c = context.lapse.colors;
    return Semantics(
      label: 'Step $filled of $segments',
      excludeSemantics: true,
      child: Row(
        children: [
          for (var i = 0; i < segments; i++) ...[
            if (i > 0) const SizedBox(width: Space.sm),
            Expanded(
              child: Container(
                key: ValueKey('setup-progress-$i'),
                height: height,
                decoration: BoxDecoration(
                  color: i < filled ? c.primary : c.ringTrack,
                  borderRadius: BorderRadius.circular(Radii.pill),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
