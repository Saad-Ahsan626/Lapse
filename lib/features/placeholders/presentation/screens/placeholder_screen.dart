import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:lapse/app/router/routes.dart';
import 'package:lapse/core/theme/theme.dart';
import 'package:lapse/core/widgets/widgets.dart';

class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({
    required this.title,
    required this.designRef,
    required this.phase,
    this.showRouteLinks = false,
    super.key,
  });

  final String title;

  final String designRef;
  final int phase;

  final bool showRouteLinks;

  static const _links = <(String, String)>[
    ('Splash', Routes.splash),
    ('Onboarding', Routes.onboarding),
    ('Permission', Routes.permission),
    ('Setup', Routes.setup),
    ('All subscriptions', Routes.subscriptions),
    ('Add subscription', Routes.newSubscription),
    ('Detail (demo)', '/subscription/demo'),
    ('Edit (demo)', '/subscription/demo/edit'),
    ('Settings', Routes.settings),
  ];

  @override
  Widget build(BuildContext context) {
    final lapse = context.lapse;
    return Scaffold(
      appBar: context.canPop() ? AppBar() : null,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(Space.screen),
          children: [
            if (!context.canPop()) ...[
              const Align(
                alignment: Alignment.centerLeft,
                child: Wordmark(height: 36),
              ),
              const SizedBox(height: Space.xxxl),
            ],
            Text(
              'DESIGN SCREEN $designRef · PHASE $phase',
              style: lapse.text.caption,
            ),
            const SizedBox(height: Space.sm),
            Text(title, style: lapse.text.title),
            const SizedBox(height: Space.sm),
            Text(
              'Placeholder. This screen is built in Phase $phase.',
              style: lapse.text.bodyMuted,
            ),
            if (showRouteLinks) ...[
              const SizedBox(height: Space.xxl),
              if (kDebugMode) ...[
                LapseButton(
                  label: 'Open design gallery',
                  icon: Icons.palette_outlined,
                  expand: true,
                  onPressed: () => context.push(Routes.gallery),
                ),
                const SizedBox(height: Space.sm),
                LapseButton(
                  label: 'Open data inspector',
                  icon: Icons.storage_rounded,
                  expand: true,
                  onPressed: () => context.push(Routes.dataInspector),
                ),
                const SizedBox(height: Space.md),
              ],
              for (final (label, path) in _links) ...[
                LapseButton(
                  label: label,
                  variant: LapseButtonVariant.secondary,
                  expand: true,
                  onPressed: () => context.push(path),
                ),
                const SizedBox(height: Space.sm),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
