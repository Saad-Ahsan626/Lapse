import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _allowed = {
  'lib/features/reminders/application/reminder_sync_controller.dart',
  'lib/features/splash/presentation/splash_timeline.dart',
  'lib/core/widgets/motion/confetti_burst.dart',
  'lib/core/widgets/layout/lapse_bottom_sheet.dart',
};

void main() {
  test('no raw millisecond durations outside core/motion', () {
    final offenders = <String>[];
    final files = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'));
    for (final file in files) {
      final path = file.path.replaceAll(r'\', '/');
      if (path.startsWith('lib/core/motion/')) continue;
      if (_allowed.contains(path)) continue;
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (lines[i].contains('Duration(milliseconds')) {
          offenders.add('$path:${i + 1}');
        }
      }
    }
    expect(offenders, isEmpty);
  });

  test('allow-listed files still exist', () {
    for (final path in _allowed) {
      expect(File(path).existsSync(), isTrue, reason: path);
    }
  });
}
