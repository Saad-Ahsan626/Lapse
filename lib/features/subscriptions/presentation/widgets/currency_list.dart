import 'package:flutter/material.dart';

import 'package:lapse/core/domain/currency_info.dart';
import 'package:lapse/core/theme/theme.dart';

class CurrencyList extends StatelessWidget {
  const CurrencyList({
    required this.selected,
    required this.onSelected,
    this.query = '',
    this.pinned,
    this.shrinkWrap = false,
    this.padding = EdgeInsets.zero,
    this.horizontalInset = Space.screen,
    this.controller,
    super.key,
  });

  final String selected;
  final ValueChanged<String> onSelected;
  final String query;
  final String? pinned;
  final bool shrinkWrap;
  final EdgeInsetsGeometry padding;
  final double horizontalInset;
  final ScrollController? controller;

  static const double rowExtent = 58;

  static List<CurrencyInfo> ordered({String? pinned, String? selected}) {
    final all = [...supportedCurrencies];
    if (selected != null && selected.trim().isNotEmpty) {
      final info = currencyInfo(selected);
      if (!all.contains(info)) all.insert(0, info);
    }
    if (pinned != null && pinned.trim().isNotEmpty) {
      final info = currencyInfo(pinned);
      all
        ..remove(info)
        ..insert(0, info);
    }
    return all;
  }

  static List<CurrencyInfo> filter(
    String query, {
    String? pinned,
    String? selected,
  }) {
    final all = ordered(pinned: pinned, selected: selected);
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return all;
    return [
      for (final info in all)
        if (info.code.toLowerCase().contains(q) ||
            info.name.toLowerCase().contains(q) ||
            info.symbol.toLowerCase() == q)
          info,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final lapse = context.lapse;
    final results = filter(query, pinned: pinned, selected: selected);
    if (results.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(Space.xl),
        child: Text(
          'No currency matches “${query.trim()}”',
          textAlign: TextAlign.center,
          style: lapse.text.bodyMuted,
        ),
      );
    }
    return ListView.separated(
      controller: controller,
      shrinkWrap: shrinkWrap,
      padding: padding,
      itemCount: results.length,
      separatorBuilder: (_, _) => Divider(
        height: 1,
        thickness: 1,
        indent: horizontalInset,
        endIndent: horizontalInset,
        color: lapse.colors.border,
      ),
      itemBuilder: (context, index) {
        final info = results[index];
        return _CurrencyRow(
          info: info,
          selected: info.code == selected.trim().toUpperCase(),
          inset: horizontalInset,
          onTap: () => onSelected(info.code),
        );
      },
    );
  }
}

class _CurrencyRow extends StatelessWidget {
  const _CurrencyRow({
    required this.info,
    required this.selected,
    required this.inset,
    required this.onTap,
  });

  final CurrencyInfo info;
  final bool selected;
  final double inset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final lapse = context.lapse;
    final c = lapse.colors;
    return Semantics(
      button: true,
      selected: selected,
      label: '${info.name}, ${info.code}',
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        color: selected ? c.primaryTint : Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: CurrencyList.rowExtent,
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: inset,
                vertical: Space.sm,
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 44,
                    child: Text(
                      info.symbol,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: lapse.text.itemTitle.copyWith(
                        fontWeight: FontWeight.w700,
                        color: selected ? c.primary : c.inkMuted,
                      ),
                    ),
                  ),
                  const SizedBox(width: Space.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(info.name, style: lapse.text.itemTitle),
                        Text(info.code, style: lapse.text.meta),
                      ],
                    ),
                  ),
                  const SizedBox(width: Space.sm),
                  SizedBox(
                    width: 24,
                    child: selected
                        ? Icon(
                            Icons.check_circle_rounded,
                            size: 24,
                            color: c.primary,
                          )
                        : null,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
