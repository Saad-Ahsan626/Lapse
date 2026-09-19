import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lapse/core/widgets/widgets.dart';
import 'package:lapse/features/catalog/presentation/providers/catalog_providers.dart';
import 'package:lapse/features/catalog/presentation/widgets/catalog_picker_sheet.dart';

Future<void> showCatalogPicker(BuildContext context) async {
  ProviderScope.containerOf(
    context,
    listen: false,
  ).read(catalogQueryProvider.notifier).clear();
  final router = GoRouter.maybeOf(context);
  final location = await showLapseSheet<String>(
    context: context,
    title: 'Add subscription',
    maxHeightFactor: 0.9,
    builder: (_) => const CatalogPickerSheet(),
  );
  if (location != null && router != null) {
    unawaited(router.push<void>(location));
  }
}
