import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:lapse/core/providers/clock_providers.dart';
import 'package:lapse/features/reminders/application/reminder_providers.dart';
import 'package:lapse/features/settings/presentation/providers/settings_providers.dart';
import 'package:lapse/features/subscriptions/presentation/links/link_opener.dart';
import 'package:lapse/features/subscriptions/presentation/providers/link_opener_provider.dart';
import 'package:lapse/features/subscriptions/presentation/providers/subscription_service_providers.dart';

import '../../../helpers/fake_notification_gateway.dart';
import '../../../helpers/fake_subscription_repository.dart';
import '../../../helpers/in_memory_settings_repository.dart';
import '../../../helpers/test_clock.dart';

class RecordingLinkOpener implements LinkOpener {
  RecordingLinkOpener({this.result = true});

  bool result;
  bool fails = false;
  final List<Uri> opened = [];

  @override
  Future<bool> open(Uri uri) async {
    opened.add(uri);
    if (fails) throw StateError('no browser');
    return result;
  }
}

class ReminderHarness {
  ReminderHarness({
    FakeNotificationGateway? gateway,
    FakeSubscriptionRepository? repository,
    InMemorySettingsRepository? settings,
    TestClock? clock,
    RecordingLinkOpener? linkOpener,
  }) : gateway = gateway ?? FakeNotificationGateway(),
       repository = repository ?? FakeSubscriptionRepository(),
       settings = settings ?? InMemorySettingsRepository(),
       clock = clock ?? TestClock(DateTime(2026, 9, 19, 10)),
       linkOpener = linkOpener ?? RecordingLinkOpener();

  final FakeNotificationGateway gateway;
  final FakeSubscriptionRepository repository;
  final InMemorySettingsRepository settings;
  final TestClock clock;
  final RecordingLinkOpener linkOpener;
  String timezone = 'Asia/Karachi';
  int timezoneCalls = 0;

  List<Override> get overrides => [
    notificationGatewayProvider.overrideWithValue(gateway),
    subscriptionRepositoryProvider.overrideWithValue(repository),
    settingsRepositoryProvider.overrideWithValue(settings),
    clockProvider.overrideWithValue(clock.call),
    newIdProvider.overrideWithValue(SequentialIds().call),
    linkOpenerProvider.overrideWithValue(linkOpener),
    configureTimezoneProvider.overrideWithValue(() async {
      timezoneCalls++;
      return timezone;
    }),
  ];

  ProviderContainer container([List<Override> extra = const []]) =>
      ProviderContainer(overrides: [...overrides, ...extra]);
}
