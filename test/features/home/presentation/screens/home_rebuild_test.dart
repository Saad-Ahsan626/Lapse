import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lapse/core/providers/clock_providers.dart';
import 'package:lapse/features/home/presentation/screens/home_screen.dart';
import 'package:lapse/features/home/presentation/widgets/home_header.dart';
import 'package:lapse/features/home/presentation/widgets/home_hero_card.dart';
import 'package:lapse/features/home/presentation/widgets/trials_strip.dart';
import 'package:lapse/features/home/presentation/widgets/upcoming_section.dart';
import 'package:lapse/features/settings/presentation/providers/settings_providers.dart';

import '../../../../helpers/rebuild_counter.dart';
import '../../home_harness.dart';
import 'home_screen_test.dart' show populated;

void main() {
  testWidgets('a day tick on the same day rebuilds no section', (
    tester,
  ) async {
    await pumpHome(tester, subscriptions: populated());
    expect(find.byType(HomeHeroCard), findsOneWidget);
    expect(find.byType(TrialsStrip), findsOneWidget);
    expect(find.byType(UpcomingSection), findsOneWidget);

    final counter = RebuildCounter()..start();
    ProviderScope.containerOf(
      tester.element(find.byType(HomeScreen)),
    ).read(dayTickProvider.notifier).bump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(counter.of(HomeScreen), 0);
    expect(counter.of(HomeHeader), 0);
    expect(counter.of(HomeHeroCard), 0);
    expect(counter.of(TrialsStrip), 0);
    expect(counter.of(UpcomingSection), 0);
  });

  testWidgets('a name change rebuilds the header and nothing else', (
    tester,
  ) async {
    await pumpHome(tester, subscriptions: populated());

    final counter = RebuildCounter()..start();
    await ProviderScope.containerOf(
          tester.element(find.byType(HomeScreen)),
        )
        .read(settingsProvider.notifier)
        .update(
          (s) => s.copyWith(userName: 'Sara'),
        );
    await tester.pump();

    expect(find.textContaining('Sara'), findsOneWidget);
    expect(counter.of(HomeHeader), greaterThan(0));
    expect(counter.of(HomeScreen), 0);
    expect(counter.of(HomeHeroCard), 0);
    expect(counter.of(TrialsStrip), 0);
    expect(counter.of(UpcomingSection), 0);
  });
}
