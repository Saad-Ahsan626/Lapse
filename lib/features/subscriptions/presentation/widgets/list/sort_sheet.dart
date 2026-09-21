import 'package:flutter/material.dart';

import 'package:lapse/core/theme/theme.dart';
import 'package:lapse/core/widgets/widgets.dart';
import 'package:lapse/features/subscriptions/presentation/providers/subscription_sort.dart';

Future<SubscriptionSort?> showSortSheet(
  BuildContext context,
  SubscriptionSort current,
) => showLapseSheet<SubscriptionSort>(
  context: context,
  title: 'Sort by',
  builder: (sheetContext) => SortSheet(
    current: current,
    onSelected: (sort) => Navigator.of(sheetContext).pop(sort),
  ),
);

class SortSheet extends StatelessWidget {
  const SortSheet({
    required this.current,
    required this.onSelected,
    super.key,
  });

  final SubscriptionSort current;
  final ValueChanged<SubscriptionSort> onSelected;

  @override
  Widget build(BuildContext context) {
    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.only(bottom: Space.xl),
      children: [
        for (final sort in SubscriptionSort.values)
          _SortOption(
            sort: sort,
            selected: sort == current,
            onTap: () => onSelected(sort),
          ),
      ],
    );
  }
}

class _SortOption extends StatelessWidget {
  const _SortOption({
    required this.sort,
    required this.selected,
    required this.onTap,
  });

  final SubscriptionSort sort;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final lapse = context.lapse;
    return Semantics(
      button: true,
      selected: selected,
      label: sort.label,
      excludeSemantics: true,
      onTap: onTap,
      child: InkWell(
        onTap: onTap,
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
                  child: Text(sort.label, style: lapse.text.itemTitle),
                ),
                if (selected)
                  Icon(
                    Icons.check_rounded,
                    size: 22,
                    color: lapse.colors.primary,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
