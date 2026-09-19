import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lapse/features/debug/presentation/screens/design_gallery_screen.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  for (final brightness in Brightness.values) {
    for (final scale in const [1.0, 2.0]) {
      testWidgets('gallery renders — ${brightness.name}, text ×$scale', (
        tester,
      ) async {
        tester.view
          ..physicalSize = const Size(390, 5000)
          ..devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        await tester.pumpLapse(
          const DesignGalleryScreen(),
          brightness: brightness,
          textScale: scale,
          wrapInScaffold: false,
          withProviders: true,
        );
        await tester.pump(const Duration(seconds: 1));

        expect(tester.takeException(), isNull);
        expect(find.text('Design gallery'), findsOneWidget);
      });
    }
  }
}
