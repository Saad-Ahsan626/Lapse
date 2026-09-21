import 'package:flutter/material.dart';

import 'package:lapse/core/theme/theme.dart';
import 'package:lapse/features/subscriptions/presentation/widgets/list/sort_button.dart';

class SubscriptionsTopBar extends StatelessWidget {
  const SubscriptionsTopBar({this.onBack, super.key});

  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final lapse = context.lapse;
    final back = onBack;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        back == null ? Space.screen : Space.xs,
        Space.md,
        Space.screen,
        Space.md,
      ),
      child: Row(
        children: [
          if (back != null)
            Semantics(
              button: true,
              label: 'Back',
              excludeSemantics: true,
              onTap: back,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: back,
                child: SizedBox.square(
                  dimension: Sizes.minTap,
                  child: Icon(
                    Icons.chevron_left_rounded,
                    size: 30,
                    color: lapse.colors.ink,
                  ),
                ),
              ),
            ),
          Expanded(
            flex: 3,
            child: Semantics(
              header: true,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  'Subscriptions',
                  maxLines: 1,
                  style: lapse.text.title,
                ),
              ),
            ),
          ),
          const SizedBox(width: Space.md),
          const Flexible(flex: 2, child: SortButton()),
        ],
      ),
    );
  }
}
