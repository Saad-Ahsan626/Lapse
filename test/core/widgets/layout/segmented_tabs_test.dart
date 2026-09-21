import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lapse/core/widgets/layout/segmented_tab.dart';
import 'package:lapse/core/widgets/layout/segmented_tabs.dart';

import '../../../helpers/pump_app.dart';

const List<SegmentedTab<String>> _tabs = [
  SegmentedTab(value: 'active', label: 'Active', count: 7),
  SegmentedTab(value: 'trials', label: 'Trials', count: 2),
  SegmentedTab(value: 'cancelled', label: 'Cancelled', count: 4),
];

Widget _tabsWith(String selected, ValueChanged<String> onChanged) => SizedBox(
  width: 360,
  child: SegmentedTabs<String>(
    tabs: _tabs,
    selected: selected,
    onChanged: onChanged,
  ),
);

void main() {
  group('SegmentedTabs', () {
    testWidgets('shows labels with counts and is at least 44 tall', (
      tester,
    ) async {
      await tester.pumpLapse(_tabsWith('active', (_) {}));

      expect(find.text('Active 7', findRichText: true), findsOneWidget);
      expect(find.text('Trials 2', findRichText: true), findsOneWidget);
      expect(find.text('Cancelled 4', findRichText: true), findsOneWidget);
      expect(
        tester.getSize(find.byType(SegmentedTabs<String>)).height,
        greaterThanOrEqualTo(44),
      );
    });

    testWidgets('tapping a segment calls onChanged with its value', (
      tester,
    ) async {
      final changes = <String>[];
      await tester.pumpLapse(_tabsWith('active', changes.add));

      await tester.tap(find.text('Trials 2', findRichText: true));
      await tester.tap(find.text('Cancelled 4', findRichText: true));

      expect(changes, ['trials', 'cancelled']);
    });

    testWidgets('segments are buttons with a selected state', (tester) async {
      await tester.pumpLapse(_tabsWith('trials', (_) {}));

      expect(
        find.bySemanticsLabel('Trials, 2'),
        findsOneWidget,
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Trials, 2')),
        matchesSemantics(
          label: 'Trials, 2',
          isButton: true,
          hasSelectedState: true,
          isSelected: true,
          hasTapAction: true,
        ),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Active, 7')),
        matchesSemantics(
          label: 'Active, 7',
          isButton: true,
          hasSelectedState: true,
          hasTapAction: true,
        ),
      );
    });

    testWidgets('pill slides over 220ms, instantly with reduce motion', (
      tester,
    ) async {
      await tester.pumpLapse(_tabsWith('active', (_) {}));
      expect(
        tester.widget<AnimatedAlign>(find.byType(AnimatedAlign)).duration,
        const Duration(milliseconds: 220),
      );

      await tester.pumpLapse(
        _tabsWith('active', (_) {}),
        reduceMotion: true,
      );
      expect(
        tester.widget<AnimatedAlign>(find.byType(AnimatedAlign)).duration,
        Duration.zero,
      );
    });

    testWidgets('fits at text scale 2', (tester) async {
      await tester.pumpLapse(_tabsWith('active', (_) {}), textScale: 2);

      expect(tester.takeException(), isNull);
    });
  });
}
