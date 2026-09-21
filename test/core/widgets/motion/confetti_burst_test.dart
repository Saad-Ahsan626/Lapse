import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lapse/core/widgets/motion/confetti_burst.dart';

import '../../../helpers/pump_app.dart';

class _Host extends StatefulWidget {
  const _Host({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  bool play = false;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Center(
          child: GestureDetector(
            onTap: widget.onTap,
            child: const SizedBox.square(
              dimension: 80,
              child: Text('Under'),
            ),
          ),
        ),
        Positioned.fill(
          child: ConfettiBurst(play: play, random: Random(1), height: 400),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: GestureDetector(
            onTap: () => setState(() => play = !play),
            child: const SizedBox(height: 60, child: Text('Toggle')),
          ),
        ),
      ],
    );
  }
}

Finder get _paint => find.descendant(
  of: find.byType(ConfettiBurst),
  matching: find.byType(CustomPaint),
);

void main() {
  group('ConfettiBurst', () {
    testWidgets('plays once and stops after the duration', (tester) async {
      await tester.pumpLapse(ConfettiBurst(play: true, random: Random(1)));

      expect(tester.hasRunningAnimations, isTrue);
      expect(_paint, findsOneWidget);
      await tester.pump(const Duration(milliseconds: 800));
      expect(tester.hasRunningAnimations, isTrue);
      await tester.pump(const Duration(milliseconds: 900));
      expect(tester.hasRunningAnimations, isFalse);
      await tester.pump(const Duration(seconds: 2));
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('does nothing while play is false', (tester) async {
      await tester.pumpLapse(ConfettiBurst(play: false, random: Random(1)));

      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('fills the width and is height tall', (tester) async {
      await tester.pumpLapse(
        const ConfettiBurst(play: false, height: 180),
      );

      final size = tester.getSize(find.byType(ConfettiBurst));
      expect(size.height, 180);
      expect(size.width, 800);
    });

    testWidgets('paints nothing and never animates under reduce motion', (
      tester,
    ) async {
      await tester.pumpLapse(
        ConfettiBurst(play: true, random: Random(1)),
        reduceMotion: true,
      );

      expect(tester.hasRunningAnimations, isFalse);
      expect(_paint, findsNothing);
      expect(tester.getSize(find.byType(ConfettiBurst)).height, 220);
    });

    testWidgets('replays when play flips from false to true', (tester) async {
      await tester.pumpLapse(_Host(onTap: () {}), wrapInScaffold: false);
      expect(tester.hasRunningAnimations, isFalse);

      await tester.tap(find.text('Toggle'));
      await tester.pump();
      expect(tester.hasRunningAnimations, isTrue);
      await tester.pump(const Duration(seconds: 2));
      expect(tester.hasRunningAnimations, isFalse);

      await tester.tap(find.text('Toggle'));
      await tester.pump(const Duration(seconds: 1));
      expect(tester.hasRunningAnimations, isFalse);

      await tester.tap(find.text('Toggle'));
      await tester.pump();
      expect(tester.hasRunningAnimations, isTrue);
      await tester.pump(const Duration(seconds: 2));
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('never intercepts taps', (tester) async {
      var taps = 0;
      await tester.pumpLapse(
        _Host(onTap: () => taps++),
        wrapInScaffold: false,
      );
      await tester.tap(find.text('Toggle'));
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.text('Under'));
      await tester.pump(const Duration(milliseconds: 100));

      expect(taps, 1);
      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('is hidden from semantics', (tester) async {
      await tester.pumpLapse(ConfettiBurst(play: true, random: Random(1)));

      expect(
        find.descendant(
          of: find.byType(ConfettiBurst),
          matching: find.byType(ExcludeSemantics),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(ConfettiBurst),
          matching: find.byType(IgnorePointer),
        ),
        findsOneWidget,
      );
      await tester.pump(const Duration(seconds: 2));
    });
  });
}
