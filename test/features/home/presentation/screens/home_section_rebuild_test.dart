import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lapse/core/widgets/widgets.dart';
import 'package:lapse/features/home/presentation/screens/home_screen.dart';
import 'package:lapse/features/home/presentation/widgets/home_add_fab.dart';
import 'package:lapse/features/home/presentation/widgets/home_header.dart';
import 'package:lapse/features/home/presentation/widgets/home_hero_card.dart';
import 'package:lapse/features/home/presentation/widgets/home_hero_section.dart';
import 'package:lapse/features/home/presentation/widgets/home_trials_section.dart';
import 'package:lapse/features/home/presentation/widgets/home_upcoming_section.dart';
import 'package:lapse/features/home/presentation/widgets/trials_strip.dart';
import 'package:lapse/features/home/presentation/widgets/upcoming_section.dart';
import 'package:lapse/features/subscriptions/domain/entities/subscription.dart';

import '../../../../helpers/fake_subscription_repository.dart';
import '../../../../helpers/rebuild_counter.dart';
import '../../home_harness.dart';
import 'home_screen_test.dart' show populated;

class EchoingSubscriptionRepository extends FakeSubscriptionRepository {
  final StreamController<List<Subscription>> _echo =
      StreamController<List<Subscription>>.broadcast();

  @override
  Stream<List<Subscription>> watchAll() async* {
    yield subscriptions.values.toList();
    yield* _echo.stream;
  }

  @override
  Future<void> upsert(Subscription subscription) async {
    await super.upsert(subscription);
    _echo.add(subscriptions.values.toList());
  }
}

const List<Type> _sections = [
  HomeHeroSection,
  HomeHeroCard,
  HomeTrialsSection,
  TrialsStrip,
  HomeUpcomingSection,
  UpcomingSection,
];

void main() {
  testWidgets('a no-op upsert rebuilds neither Home nor its sections', (
    tester,
  ) async {
    final repository = EchoingSubscriptionRepository();
    await pumpHome(
      tester,
      subscriptions: populated(),
      repository: repository,
    );
    expect(find.byType(TrialsStrip), findsOneWidget);

    final counter = RebuildCounter()..start();
    final same = repository.subscriptions.values.first;
    await repository.upsert(same);
    await settleHome(tester);

    expect(counter.of(HomeScreen), 0);
    expect(counter.of(Scaffold), 0);
    for (final section in _sections) {
      expect(counter.of(section), 0, reason: '$section');
    }
  });

  testWidgets('opening the picker rebuilds only the FAB', (tester) async {
    await pumpHome(tester, subscriptions: populated());

    final counter = RebuildCounter()..start();
    await tester.tap(find.byType(LapseFab));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Add subscription'), findsWidgets);
    expect(tester.widget<LapseFab>(find.byType(LapseFab)).open, isTrue);
    expect(counter.of(HomeAddFab), greaterThan(0));
    expect(counter.of(HomeScreen), 0);
    expect(counter.of(HomeHeader), 0);
    for (final section in _sections) {
      expect(counter.of(section), 0, reason: '$section');
    }
  });
}
