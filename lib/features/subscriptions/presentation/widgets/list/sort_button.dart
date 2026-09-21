import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lapse/core/theme/theme.dart';
import 'package:lapse/features/subscriptions/presentation/providers/subscription_tab_providers.dart';
import 'package:lapse/features/subscriptions/presentation/widgets/list/sort_sheet.dart';

class SortButton extends ConsumerWidget {
  const SortButton({super.key});

  static const double height = 36;

  Future<void> _open(BuildContext context, WidgetRef ref) async {
    final picked = await showSortSheet(
      context,
      ref.read(subscriptionSortProvider),
    );
    if (picked == null) return;
    ref.read(subscriptionSortProvider.notifier).select(picked);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lapse = context.lapse;
    final c = lapse.colors;
    final sort = ref.watch(subscriptionSortProvider);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(Radii.pill),
      side: BorderSide(color: c.border),
    );

    return Semantics(
      button: true,
      label: 'Sort by ${sort.label}',
      excludeSemantics: true,
      onTap: () => _open(context, ref),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: Sizes.minTap),
        child: Center(
          child: Material(
            color: c.surface,
            shape: shape,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => _open(context, ref),
              customBorder: shape,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: height),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Space.md),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.sort_rounded, size: 18, color: c.ink),
                      const SizedBox(width: Space.sm),
                      Flexible(
                        child: Text(
                          sort.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: lapse.text.chip.copyWith(color: c.ink),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
