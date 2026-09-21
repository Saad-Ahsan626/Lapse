import 'package:flutter/material.dart';

import 'package:lapse/core/domain/urgency.dart';
import 'package:lapse/core/theme/theme.dart';
import 'package:lapse/core/widgets/widgets.dart';
import 'package:lapse/features/debug/presentation/widgets/gallery_section.dart';

enum _GalleryTab { active, trials, cancelled }

class ListsMotionSection extends StatefulWidget {
  const ListsMotionSection({super.key});

  @override
  State<ListsMotionSection> createState() => _ListsMotionSectionState();
}

class _ListsMotionSectionState extends State<ListsMotionSection> {
  static const _amounts = [51840, 12990, 249900];

  int _amountIndex = 0;
  int _countKey = 0;
  int _entranceKey = 0;
  _GalleryTab _tab = _GalleryTab.active;
  String _lastAction = 'Swipe a row left';

  void _log(String message) => setState(() => _lastAction = message);

  @override
  Widget build(BuildContext context) {
    final c = context.lapse.colors;
    final text = context.lapse.text;
    final actions = [
      SwipeAction(
        label: 'Cancelled',
        icon: Icons.check_rounded,
        color: c.savings,
        foregroundColor: c.onTrial,
        onTap: () => _log('Marked cancelled'),
      ),
      SwipeAction(
        label: 'Delete',
        icon: Icons.delete_outline_rounded,
        color: c.urgent,
        foregroundColor: c.onTrial,
        onTap: () => _log('Deleted'),
      ),
    ];

    return GallerySection(
      title: 'Lists & motion',
      note: 'Square button, count-up, staggered entrance, tabs, swipe rows.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SquareIconButton(
                icon: Icons.tune_rounded,
                semanticLabel: 'Settings',
                onPressed: () => _log('Settings tapped'),
              ),
              const SizedBox(width: Space.md),
              Expanded(
                child: CountUpText(
                  key: ValueKey(_countKey),
                  value: _amounts[_amountIndex],
                  format: (v) => 'Rs $v',
                  style: text.section,
                ),
              ),
            ],
          ),
          const SizedBox(height: Space.md),
          Wrap(
            spacing: Space.sm,
            runSpacing: Space.sm,
            children: [
              LapseButton(
                label: 'Replay',
                variant: LapseButtonVariant.secondary,
                onPressed: () => setState(() => _countKey++),
              ),
              LapseButton(
                label: 'Change value',
                variant: LapseButtonVariant.secondary,
                onPressed: () => setState(
                  () => _amountIndex = (_amountIndex + 1) % _amounts.length,
                ),
              ),
              LapseButton(
                label: 'Replay rows',
                variant: LapseButtonVariant.secondary,
                onPressed: () => setState(() => _entranceKey++),
              ),
            ],
          ),
          const SizedBox(height: Space.lg),
          Column(
            key: ValueKey(_entranceKey),
            children: [
              for (var i = 0; i < 3; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: StaggeredEntrance(
                    index: i,
                    child: SubscriptionListTile(
                      name: const ['Spotify', 'Netflix', 'iCloud+'][i],
                      meta: 'Rs 299 · Monthly',
                      dueLabel: const ['Tomorrow', 'In 3 days', 'Oct 24'][i],
                      urgency: const [
                        Urgency.urgent,
                        Urgency.warning,
                        Urgency.normal,
                      ][i],
                      initials: const ['SP', 'NF', 'IC'][i],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: Space.lg),
          SegmentedTabs<_GalleryTab>(
            tabs: const [
              SegmentedTab(
                value: _GalleryTab.active,
                label: 'Active',
                count: 7,
              ),
              SegmentedTab(
                value: _GalleryTab.trials,
                label: 'Trials',
                count: 2,
              ),
              SegmentedTab(
                value: _GalleryTab.cancelled,
                label: 'Cancelled',
                count: 4,
              ),
            ],
            selected: _tab,
            onChanged: (tab) => setState(() => _tab = tab),
          ),
          const SizedBox(height: Space.lg),
          SwipeActionsGroup(
            child: Column(
              children: [
                SwipeActions(
                  actions: actions,
                  child: SubscriptionListTile(
                    name: 'ChatGPT Plus',
                    meta: 'Rs 5,600 · Monthly',
                    dueLabel: 'In 3 days',
                    urgency: Urgency.warning,
                    initials: 'GP',
                    onTap: () => _log('Row tapped'),
                  ),
                ),
                const SizedBox(height: 10),
                SwipeActions(
                  actions: actions,
                  child: SubscriptionListTile(
                    name: 'YouTube Premium',
                    meta: 'Rs 479 · Monthly',
                    dueLabel: 'Nov 02',
                    urgency: Urgency.normal,
                    initials: 'YT',
                    onTap: () => _log('Row tapped'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Space.sm),
          Text(_lastAction, style: text.meta),
          const SizedBox(height: Space.lg),
          const SkeletonRow(),
        ],
      ),
    );
  }
}
