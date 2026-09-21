import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lapse/core/theme/tokens/lapse_colors.dart';
import 'package:lapse/core/widgets/buttons/lapse_button.dart';

import '../../../helpers/pump_app.dart';

void main() {
  group('LapseButton', () {
    testWidgets('calls onPressed when tapped', (tester) async {
      var taps = 0;
      await tester.pumpLapse(
        LapseButton(label: 'Save', onPressed: () => taps++),
      );

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(taps, 1);
    });

    testWidgets('is disabled and at 40% opacity without onPressed', (
      tester,
    ) async {
      await tester.pumpLapse(const LapseButton(label: 'Save', onPressed: null));

      final opacity = tester.widget<AnimatedOpacity>(
        find.byType(AnimatedOpacity),
      );
      expect(opacity.opacity, 0.4);
      expect(
        tester.getSemantics(find.byType(LapseButton)),
        matchesSemantics(
          label: 'Save',
          isButton: true,
          hasEnabledState: true,
        ),
      );
    });

    testWidgets('is 48px tall', (tester) async {
      await tester.pumpLapse(LapseButton(label: 'Save', onPressed: () {}));

      expect(tester.getSize(find.byType(Material).last).height, 48);
    });

    testWidgets('does not scale on press when reduce motion is on', (
      tester,
    ) async {
      await tester.pumpLapse(
        LapseButton(label: 'Save', onPressed: () {}),
        reduceMotion: true,
      );

      final gesture = await tester.startGesture(
        tester.getCenter(find.text('Save')),
      );
      await tester.pump(const Duration(milliseconds: 200));

      expect(tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, 1);
      await gesture.up();
    });

    testWidgets('scales to 0.97 while pressed', (tester) async {
      await tester.pumpLapse(LapseButton(label: 'Save', onPressed: () {}));

      final gesture = await tester.startGesture(
        tester.getCenter(find.text('Save')),
      );
      await tester.pump();

      expect(
        tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale,
        0.97,
      );
      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('loading shows a spinner and ignores taps', (tester) async {
      var taps = 0;
      await tester.pumpLapse(
        LapseButton(label: 'Save', loading: true, onPressed: () => taps++),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Save'), findsNothing);
      await tester.tap(find.byType(LapseButton));
      await tester.pump();
      expect(taps, 0);
      expect(
        tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity,
        1,
      );
    });

    for (final (brightness, colors) in [
      (Brightness.light, LapseColors.light),
      (Brightness.dark, LapseColors.dark),
    ]) {
      testWidgets('inverse uses ink and background in ${brightness.name}', (
        tester,
      ) async {
        await tester.pumpLapse(
          LapseButton(
            label: 'Done',
            variant: LapseButtonVariant.inverse,
            onPressed: () {},
          ),
          brightness: brightness,
        );

        final material = tester.widget<Material>(
          find.descendant(
            of: find.byType(LapseButton),
            matching: find.byType(Material),
          ),
        );
        expect(material.color, colors.ink);
        final shape = material.shape! as RoundedRectangleBorder;
        expect(shape.side, BorderSide.none);
        expect(
          tester.widget<Text>(find.text('Done')).style?.color,
          colors.background,
        );
      });
    }
  });
}
