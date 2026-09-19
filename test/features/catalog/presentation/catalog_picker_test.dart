import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lapse/features/catalog/data/logo_availability.dart';
import 'package:lapse/features/catalog/presentation/providers/catalog_providers.dart';
import 'package:lapse/features/catalog/presentation/widgets/catalog_popular_grid.dart';
import 'package:lapse/features/catalog/presentation/widgets/catalog_result_row.dart';
import 'package:lapse/features/catalog/presentation/widgets/catalog_results_list.dart';
import 'package:lapse/features/catalog/presentation/widgets/catalog_service_card.dart';
import 'package:lapse/features/catalog/presentation/widgets/custom_subscription_card.dart';
import 'package:lapse/features/catalog/presentation/widgets/recent_custom_list.dart';
import 'package:lapse/features/subscriptions/domain/entities/billing_period.dart';
import 'package:lapse/features/subscriptions/presentation/providers/subscription_list_providers.dart';

import '../../../helpers/fake_catalog_repository.dart';
import '../../../helpers/subscription_fixtures.dart';
import 'catalog_picker_harness.dart';

void main() {
  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pump();
    await tester.tap(finder);
    await settle(tester);
  }

  Future<void> search(WidgetTester tester, String text) async {
    await tester.enterText(find.byType(TextField), text);
    await settle(tester);
  }

  testWidgets('shows the header, search hint and 11 popular + custom', (
    tester,
  ) async {
    await pumpPickerApp(tester);
    await openPicker(tester);

    expect(find.text('Add subscription'), findsOneWidget);
    expect(find.text('Search services'), findsOneWidget);
    expect(find.text('POPULAR'), findsOneWidget);
    expect(find.byType(CatalogServiceCard), findsNWidgets(11));
    expect(find.byType(CustomSubscriptionCard), findsOneWidget);
    for (final name in popularNames) {
      expect(find.text(name), findsOneWidget);
    }
    expect(find.text('Custom subscription'), findsOneWidget);
    expect(find.byKey(const ValueKey('catalog-search-clear')), findsNothing);
    final card = tester.getSize(find.byType(CatalogServiceCard).last);
    expect(card.height, greaterThanOrEqualTo(CatalogServiceCard.minHeight));
  });

  testWidgets('typing "spo" ranks Spotify first and ends with custom row', (
    tester,
  ) async {
    await pumpPickerApp(tester);
    await openPicker(tester);
    await search(tester, 'spo');

    expect(find.byType(CatalogPopularGrid), findsNothing);
    final rows = tester.widgetList<CatalogResultRow>(
      find.byType(CatalogResultRow),
    );
    final titles = rows.map((r) => r.title).toList();
    expect(titles, [
      'Spotify',
      'Spotify Family',
      'Add “spo” as custom',
    ]);
    expect(find.text('Other'), findsNWidgets(2));
    expect(find.text(CatalogResultsList.noResultsText), findsNothing);
  });

  testWidgets('no results shows the message and only the custom row', (
    tester,
  ) async {
    await pumpPickerApp(tester);
    await openPicker(tester);
    await search(tester, 'zzzq');

    expect(find.text(CatalogResultsList.noResultsText), findsOneWidget);
    expect(find.byType(CatalogResultRow), findsOneWidget);
    expect(find.text('Add “zzzq” as custom'), findsOneWidget);
  });

  testWidgets('clear button empties the query and restores the grid', (
    tester,
  ) async {
    await pumpPickerApp(tester);
    await openPicker(tester);
    await search(tester, 'spo');

    final clear = find.byKey(const ValueKey('catalog-search-clear'));
    expect(clear, findsOneWidget);
    await tester.tap(clear);
    await settle(tester);

    expect(find.byType(CatalogPopularGrid), findsOneWidget);
    expect(clear, findsNothing);
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, isEmpty);
  });

  testWidgets('tapping a popular service closes the sheet and navigates', (
    tester,
  ) async {
    final visited = await pumpPickerApp(tester);
    await openPicker(tester);
    await tapVisible(tester, find.text('Spotify'));

    expect(find.text('Add subscription'), findsNothing);
    expect(find.text('New subscription form'), findsOneWidget);
    expect(visited.last.toString(), '/subscription/new?service=spotify');
  });

  testWidgets('tapping a search result navigates with its key', (
    tester,
  ) async {
    final visited = await pumpPickerApp(tester);
    await openPicker(tester);
    await search(tester, 'spo');
    await tapVisible(tester, find.text('Spotify'));

    expect(visited.last.toString(), '/subscription/new?service=spotify');
  });

  testWidgets('custom card opens an empty form', (tester) async {
    final visited = await pumpPickerApp(tester);
    await openPicker(tester);
    await tapVisible(tester, find.byType(CustomSubscriptionCard));

    expect(find.text('New subscription form'), findsOneWidget);
    expect(visited.last.toString(), '/subscription/new');
    expect(visited.last.queryParameters, isEmpty);
  });

  testWidgets('"as custom" row passes the typed name', (tester) async {
    final visited = await pumpPickerApp(tester);
    await openPicker(tester);
    await search(tester, 'Gym');
    await tapVisible(tester, find.text('Add “Gym” as custom'));

    expect(visited.last.path, '/subscription/new');
    expect(visited.last.queryParameters, {'name': 'Gym'});
  });

  testWidgets('recent section is hidden when there are none', (tester) async {
    await pumpPickerApp(tester);
    await openPicker(tester);

    expect(find.text(RecentCustomList.caption), findsNothing);
  });

  testWidgets('recent custom rows show and navigate with the name', (
    tester,
  ) async {
    final visited = await pumpPickerApp(
      tester,
      overrides: pickerOverrides(
        recent: [
          subscriptionFixture(id: 'gym', name: 'Gym membership'),
          subscriptionFixture(
            id: 'paper',
            name: 'Newspaper',
            period: BillingPeriod.weekly,
          ),
        ],
      ),
    );
    await openPicker(tester);

    final caption = find.text(RecentCustomList.caption);
    await tester.ensureVisible(caption);
    await tester.pump();
    expect(caption, findsOneWidget);
    expect(find.text('Gym membership'), findsOneWidget);
    expect(find.text('Custom · Monthly'), findsOneWidget);
    expect(find.text('Custom · Weekly'), findsOneWidget);

    await tapVisible(tester, find.text('Gym membership'));
    expect(visited.last.queryParameters, {'name': 'Gym membership'});
  });

  testWidgets('recent rows come from saved custom subscriptions', (
    tester,
  ) async {
    await pumpPickerApp(
      tester,
      overrides: [
        catalogRepositoryProvider.overrideWithValue(
          FakeCatalogRepository(pickerCatalog),
        ),
        logoAvailabilityProvider.overrideWith(
          (ref) async => LogoAvailability({}),
        ),
        subscriptionsProvider.overrideWith(
          (ref) => Stream.value([
            subscriptionFixture(id: 'gym', name: 'Gym membership'),
          ]),
        ),
      ],
    );
    await openPicker(tester);

    await tester.ensureVisible(find.text('Gym membership'));
    await tester.pump();
    expect(find.text(RecentCustomList.caption), findsOneWidget);
  });

  testWidgets('close button closes the sheet', (tester) async {
    final visited = await pumpPickerApp(tester);
    await openPicker(tester);

    await tester.tap(find.bySemanticsLabel('Close'));
    await settle(tester);

    expect(find.text('Add subscription'), findsNothing);
    expect(find.text('Open picker'), findsOneWidget);
    expect(visited, isEmpty);
  });

  testWidgets('opening again clears the previous query', (tester) async {
    await pumpPickerApp(tester);
    await openPicker(tester);
    await search(tester, 'spo');
    await tester.tap(find.bySemanticsLabel('Close'));
    await settle(tester);

    await openPicker(tester);
    expect(find.byType(CatalogPopularGrid), findsOneWidget);
  });

  testWidgets('load failure shows retry, which reloads the catalog', (
    tester,
  ) async {
    final repository = FakeCatalogRepository(pickerCatalog, fail: true);
    await pumpPickerApp(
      tester,
      overrides: pickerOverrides(repository: repository),
    );
    await openPicker(tester);

    expect(find.text('Retry'), findsOneWidget);
    repository.fail = false;
    await tester.tap(find.text('Retry'));
    await settle(tester);

    expect(find.byType(CatalogServiceCard), findsNWidgets(11));
  });

  testWidgets('renders in dark mode at text scale 2 without overflow', (
    tester,
  ) async {
    await pumpPickerApp(
      tester,
      brightness: Brightness.dark,
      textScale: 2,
      overrides: pickerOverrides(
        recent: [subscriptionFixture(name: 'A very long gym membership name')],
      ),
    );
    await openPicker(tester);

    expect(find.byType(CatalogServiceCard), findsNWidgets(11));
    await tester.scrollUntilVisible(
      find.text(RecentCustomList.caption),
      300,
      scrollable: find
          .byWidgetPredicate(
            (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
          )
          .last,
    );
    await tester.pump();
    await search(tester, 'spo');
    expect(find.byType(CatalogResultRow), findsNWidgets(3));
    expect(tester.takeException(), isNull);
  });

  testWidgets('cards and rows expose button semantics', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpPickerApp(tester);
    await openPicker(tester);

    expect(
      tester.getSemantics(find.byType(CustomSubscriptionCard)),
      matchesSemantics(
        label: 'Custom subscription',
        isButton: true,
        hasTapAction: true,
      ),
    );
    expect(
      tester.getSize(find.byType(CatalogServiceCard).first).height,
      greaterThanOrEqualTo(44),
    );
    handle.dispose();
  });
}
