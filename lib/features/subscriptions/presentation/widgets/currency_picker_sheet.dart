import 'package:flutter/material.dart';

import 'package:lapse/core/domain/currency_info.dart';
import 'package:lapse/core/theme/theme.dart';
import 'package:lapse/core/widgets/widgets.dart';
import 'package:lapse/features/subscriptions/presentation/widgets/currency_list.dart';

Future<String?> showCurrencyPicker(BuildContext context, String selected) =>
    showLapseSheet<String>(
      context: context,
      title: 'Currency',
      builder: (_) => CurrencyPickerSheet(selected: selected),
    );

class CurrencyPickerSheet extends StatefulWidget {
  const CurrencyPickerSheet({required this.selected, super.key});

  final String selected;

  static List<CurrencyInfo> filter(String query) => CurrencyList.filter(query);

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
    final c = context.lapse.colors;
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
              leading: ExcludeSemantics(
                child: Icon(
                  Icons.search_rounded,
                  size: 22,
                  color: c.inkSubtle,
                ),
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
        ),
        Flexible(
          child: CurrencyList(
            selected: widget.selected,
            query: _query,
            shrinkWrap: true,
            padding: const EdgeInsets.only(bottom: Space.xl),
            onSelected: (code) => Navigator.of(context).pop(code),
          ),
        ),
      ],
    );
  }
}
