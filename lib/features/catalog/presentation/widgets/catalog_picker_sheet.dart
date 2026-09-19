import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lapse/core/theme/theme.dart';
import 'package:lapse/features/catalog/presentation/providers/catalog_providers.dart';
import 'package:lapse/features/catalog/presentation/widgets/catalog_load_error.dart';
import 'package:lapse/features/catalog/presentation/widgets/catalog_popular_grid.dart';
import 'package:lapse/features/catalog/presentation/widgets/catalog_results_list.dart';
import 'package:lapse/features/catalog/presentation/widgets/catalog_search_field.dart';
import 'package:lapse/features/catalog/presentation/widgets/recent_custom_list.dart';

class CatalogPickerSheet extends ConsumerStatefulWidget {
  const CatalogPickerSheet({super.key});

  @override
  ConsumerState<CatalogPickerSheet> createState() => _CatalogPickerSheetState();
}

class _CatalogPickerSheetState extends ConsumerState<CatalogPickerSheet> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) =>
      ref.read(catalogQueryProvider.notifier).set(value);

  void _clear() {
    _controller.clear();
    ref.read(catalogQueryProvider.notifier).clear();
  }

  void _select(String location) => Navigator.of(context).pop(location);

  @override
  Widget build(BuildContext context) {
    final lapse = context.lapse;
    final catalog = ref.watch(catalogProvider);
    final query = ref.watch(catalogQueryProvider);
    final listPadding = EdgeInsets.fromLTRB(
      Space.screen,
      0,
      Space.screen,
      Space.xxl + MediaQuery.paddingOf(context).bottom,
    );

    final body = catalog.when<Widget>(
      loading: () => const Center(
        child: SizedBox.square(
          dimension: 28,
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
      ),
      error: (_, _) =>
          CatalogLoadError(onRetry: () => ref.invalidate(catalogProvider)),
      data: (_) => query.trim().isEmpty
          ? ListView(
              padding: listPadding,
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              children: [
                Text('POPULAR', style: lapse.text.caption),
                const SizedBox(height: Space.md),
                CatalogPopularGrid(onSelect: _select),
                RecentCustomList(onSelect: _select),
              ],
            )
          : CatalogResultsList(onSelect: _select, padding: listPadding),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Space.screen),
          child: CatalogSearchField(
            controller: _controller,
            onChanged: _onChanged,
            onClear: _clear,
          ),
        ),
        const SizedBox(height: Space.xl),
        Expanded(child: body),
      ],
    );
  }
}
