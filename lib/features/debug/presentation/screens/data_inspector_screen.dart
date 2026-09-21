import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lapse/core/providers/clock_providers.dart';
import 'package:lapse/core/theme/theme.dart';
import 'package:lapse/core/widgets/widgets.dart';
import 'package:lapse/features/debug/data/sample_subscriptions.dart';
import 'package:lapse/features/debug/presentation/widgets/inspector_row.dart';
import 'package:lapse/features/debug/presentation/widgets/reminders_debug_section.dart';
import 'package:lapse/features/settings/presentation/providers/settings_providers.dart';
import 'package:lapse/features/subscriptions/presentation/providers/subscription_list_providers.dart';
import 'package:lapse/features/subscriptions/presentation/providers/subscription_service_providers.dart';

class DataInspectorScreen extends ConsumerWidget {
  const DataInspectorScreen({super.key});

  static const _month = Duration(days: 30);

  Future<void> _seed(WidgetRef ref) async {
    final save = ref.read(saveSubscriptionProvider);
    final samples = sampleSubscriptions(
      ref.read(todayProvider),
      ref.read(settingsProvider).defaultCurrency,
    );
    for (final draft in samples) {
      final saved = await save(draft);
      if (saved.name == sampleCancelledName) {
        await ref.read(markCancelledProvider)(saved.id);
      }
    }
  }

  Future<void> _rollOver(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final count = await ref.read(rollOverDueSubscriptionsProvider)();
    messenger.showSnackBar(
      SnackBar(content: Text('Rolled over $count subscription(s)')),
    );
  }

  Future<void> _clear(WidgetRef ref) =>
      ref.read(subscriptionRepositoryProvider).replaceAll(const [], const []);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lapse = context.lapse;
    final subscriptions = ref.watch(subscriptionsProvider);
    final today = ref.watch(todayProvider);
    final offset = ref.watch(clockOffsetProvider);
    final clock = ref.read(clockOffsetProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Data inspector')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          Space.screen,
          Space.sm,
          Space.screen,
          Space.xxxl,
        ),
        children: [
          const RemindersDebugSection(),
          const SizedBox(height: Space.xxl),
          Text('TODAY', style: lapse.text.caption),
          const SizedBox(height: Space.xs),
          Text(
            offset == Duration.zero
                ? '$today'
                : '$today  (time travel +${offset.inDays} days)',
            style: lapse.text.section,
          ),
          const SizedBox(height: Space.lg),
          Wrap(
            spacing: Space.sm,
            runSpacing: Space.sm,
            children: [
              LapseButton(
                label: 'Seed sample data',
                onPressed: () => _seed(ref),
              ),
              LapseButton(
                label: 'Roll over now',
                variant: LapseButtonVariant.secondary,
                onPressed: () => _rollOver(context, ref),
              ),
              LapseButton(
                label: '+1 month',
                variant: LapseButtonVariant.secondary,
                onPressed: () => clock.travel(_month),
              ),
              LapseButton(
                label: 'Reset time',
                variant: LapseButtonVariant.secondary,
                onPressed: offset == Duration.zero ? null : clock.reset,
              ),
              LapseButton(
                label: 'Clear all',
                variant: LapseButtonVariant.danger,
                onPressed: () => _clear(ref),
              ),
            ],
          ),
          const SizedBox(height: Space.xxl),
          ...subscriptions.when(
            data: (list) => [
              SectionHeader(title: 'Subscriptions (${list.length})'),
              const SizedBox(height: Space.sm),
              if (list.isEmpty)
                Text(
                  'No data. Tap "Seed sample data".',
                  style: lapse.text.bodyMuted,
                ),
              for (final subscription in list) ...[
                InspectorRow(subscription: subscription),
                const SizedBox(height: Space.md),
              ],
            ],
            loading: () => [const Center(child: CircularProgressIndicator())],
            error: (error, _) => [
              Text(
                '$error',
                style: lapse.text.body.copyWith(color: lapse.colors.urgentText),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
