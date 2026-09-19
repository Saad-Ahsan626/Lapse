import 'package:flutter_riverpod/flutter_riverpod.dart';

class CatalogQueryController extends Notifier<String> {
  @override
  String build() => '';

  void set(String query) => state = query.trimLeft();

  void clear() => state = '';
}
