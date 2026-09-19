import 'package:flutter_test/flutter_test.dart';
import 'package:lapse/core/widgets/widgets.dart';
import 'package:lapse/features/catalog/presentation/widgets/catalog_picker_sheet.dart';
import 'package:lapse/features/placeholders/presentation/screens/placeholder_screen.dart';

import '../../../catalog/presentation/catalog_picker_harness.dart';

void main() {
  const home = PlaceholderScreen(
    title: 'Home',
    designRef: '05',
    phase: 3,
    showRouteLinks: true,
  );

  bool fabOpen(WidgetTester tester) =>
      tester.widget<LapseFab>(find.byType(LapseFab)).open;

  testWidgets('home placeholder shows a closed FAB', (tester) async {
    await pumpPickerApp(tester, home: home);

    expect(find.byType(LapseFab), findsOneWidget);
    expect(fabOpen(tester), isFalse);
  });

  testWidgets('other placeholders have no FAB', (tester) async {
    await pumpPickerApp(
      tester,
      home: const PlaceholderScreen(
        title: 'Settings',
        designRef: '11',
        phase: 7,
      ),
    );

    expect(find.byType(LapseFab), findsNothing);
  });

  testWidgets('FAB opens the picker and is open while it is up', (
    tester,
  ) async {
    await pumpPickerApp(tester, home: home);

    await tester.tap(find.byType(LapseFab));
    await settle(tester);

    expect(find.byType(CatalogPickerSheet), findsOneWidget);
    expect(fabOpen(tester), isTrue);

    await tester.tap(find.bySemanticsLabel('Close'));
    await settle(tester);

    expect(find.byType(CatalogPickerSheet), findsNothing);
    expect(fabOpen(tester), isFalse);
  });

  testWidgets('choosing a service navigates and resets the FAB', (
    tester,
  ) async {
    final visited = await pumpPickerApp(tester, home: home);

    await tester.tap(find.byType(LapseFab));
    await settle(tester);
    await tester.tap(find.text('Netflix'));
    await settle(tester);

    expect(visited.last.toString(), '/subscription/new?service=netflix');
    expect(find.text('New subscription form'), findsOneWidget);
  });
}
