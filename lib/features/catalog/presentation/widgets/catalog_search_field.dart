import 'package:flutter/material.dart';
import 'package:lapse/core/theme/theme.dart';
import 'package:lapse/core/widgets/widgets.dart';

class CatalogSearchField extends StatelessWidget {
  const CatalogSearchField({
    required this.controller,
    required this.onChanged,
    required this.onClear,
    this.hint = 'Search services',
    super.key,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final c = context.lapse.colors;
    return LapseTextField(
      controller: controller,
      hint: hint,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      leading: ExcludeSemantics(
        child: Icon(Icons.search_rounded, size: 22, color: c.inkSubtle),
      ),
      trailing: ValueListenableBuilder<TextEditingValue>(
        valueListenable: controller,
        builder: (context, value, _) {
          if (value.text.isEmpty) return const SizedBox(width: 10);
          return Semantics(
            button: true,
            label: 'Clear search',
            excludeSemantics: true,
            onTap: onClear,
            child: GestureDetector(
              key: const ValueKey('catalog-search-clear'),
              behavior: HitTestBehavior.opaque,
              onTap: onClear,
              child: SizedBox.square(
                dimension: Sizes.minTap,
                child: Icon(
                  Icons.cancel_rounded,
                  size: 20,
                  color: c.inkSubtle,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
