import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

class RebuildCounter {
  final Map<Type, int> _counts = {};

  int of(Type type) => _counts[type] ?? 0;

  int named(String prefix) => _counts.entries
      .where((e) => e.key.toString().startsWith(prefix))
      .fold(0, (sum, e) => sum + e.value);

  void reset() => _counts.clear();

  void start() {
    final previous = debugOnRebuildDirtyWidget;
    debugOnRebuildDirtyWidget = (element, builtOnce) {
      final type = element.widget.runtimeType;
      _counts[type] = of(type) + 1;
    };
    addTearDown(() => debugOnRebuildDirtyWidget = previous);
  }
}
