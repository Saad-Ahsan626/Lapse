import 'package:flutter/material.dart';

import 'package:lapse/core/domain/currency_info.dart';
import 'package:lapse/core/theme/theme.dart';
import 'package:lapse/core/widgets/widgets.dart';

Future<String?> showCurrencyPicker(BuildContext context, String selected) =>
    showLapseSheet<String>(
      context: context,
      title: 'Currency',
      builder: (_) => CurrencyPickerSheet(selected: selected),
    );

class CurrencyPickerSheet extends StatefulWidget {
  const CurrencyPickerSheet({required this.selected, super.key});

  final String selected;

  static List<CurrencyInfo> filter(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return supportedCurrencies;
    return [
      for (final info in supportedCurrencies)
        if (info.code.toLowerCase().contains(q) ||
            info.name.toLowerCase().contains(q) ||
            info.symbol.toLowerCase() == q)
          info,
    ];
  }

  @override
  State<CurrencyPickerSheet> createState() => _CurrencyPickerSheetState();
}

class _CurrencyPickerSheetState extends State<CurrencyPickerSheet> {
  final TextEditingController _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lapse = context.lapse;
    final c = lapse.colors;
    final results = CurrencyPickerSheet.filter(_query);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            Space.screen,
            0,
            Space.screen,
            Space.sm,
          ),
          child: Semantics(
            label: 'Search currencies',
            child: LapseTextField(
              controller: _search,
              hint: 'Search currency',
              textInputAction: TextInputAction.search,
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
        ),
        Flexible(
          child: results.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(Space.xl),
                  child: Text(
                    'No currency matches “$_query”',
                    textAlign: TextAlign.center,
                    style: lapse.text.bodyMuted,
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.only(bottom: Space.xl),
                  itemCount: results.length,
                  itemBuilder: (context, index) {
                    final info = results[index];
                    final selected = info.code == widget.selected;
                    void pick() => Navigator.of(context).pop(info.code);
                    return Semantics(
                      button: true,
                      selected: selected,
                      label: '${info.name}, ${info.code}',
                      excludeSemantics: true,
                      onTap: pick,
                      child: InkWell(
                        onTap: pick,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: 52),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: Space.screen,
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
                                      color: c.inkMuted,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: Space.sm),
                                Expanded(
                                  child: Text(
                                    info.name,
                                    style: lapse.text.itemTitle,
                                  ),
                                ),
                                const SizedBox(width: Space.sm),
                                Text(info.code, style: lapse.text.meta),
                                SizedBox(
                                  width: 30,
                                  child: selected
                                      ? Icon(
                                          Icons.check_rounded,
                                          size: 22,
                                          color: c.primary,
                                        )
                                      : null,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
