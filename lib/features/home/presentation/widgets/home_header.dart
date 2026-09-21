import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lapse/app/router/routes.dart';
import 'package:lapse/core/providers/clock_providers.dart';
import 'package:lapse/core/theme/theme.dart';
import 'package:lapse/core/widgets/widgets.dart';
import 'package:lapse/features/settings/presentation/providers/settings_providers.dart';
import 'package:lapse/features/subscriptions/presentation/formatting/subscription_labels.dart';

class HomeHeader extends ConsumerWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = context.lapse.text;
    ref.watch(todayProvider);
    final greeting = greetingFor(ref.watch(clockProvider)());
    final name = ref.watch(
      settingsProvider.select((settings) => settings.userName?.trim() ?? ''),
    );
    final bigStyle = text.title.copyWith(
      fontSize: 28,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.8,
      height: 1.15,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Space.screen,
        Space.md,
        Space.screen,
        Space.lg,
      ),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: name.isEmpty
                    ? [Text(greeting, style: bigStyle)]
                    : [
                        Text(
                          '$greeting,',
                          style: text.bodyMuted.copyWith(fontSize: 15),
                        ),
                        Text(
                          name,
                          style: bigStyle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
              ),
            ),
          ),
          const SizedBox(width: Space.md),
          SquareIconButton(
            icon: Icons.tune_rounded,
            semanticLabel: 'Settings',
            onPressed: () => unawaited(context.push<void>(Routes.settings)),
          ),
        ],
      ),
    );
  }
}
