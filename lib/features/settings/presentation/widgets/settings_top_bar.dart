import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:lapse/app/router/routes.dart';
import 'package:lapse/core/theme/theme.dart';

class SettingsTopBar extends StatelessWidget {
  const SettingsTopBar({required this.title, super.key});

  final String title;

  void _back(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(Routes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lapse = context.lapse;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Space.xs,
        Space.md,
        Space.screen,
        Space.sm,
      ),
      child: Row(
        children: [
          Semantics(
            container: true,
            button: true,
            label: 'Back',
            excludeSemantics: true,
            onTap: () => _back(context),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _back(context),
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
          const SizedBox(width: Space.xs),
          Expanded(
            child: Semantics(
              container: true,
              header: true,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  title,
                  maxLines: 1,
                  style: lapse.text.title.copyWith(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.8,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
