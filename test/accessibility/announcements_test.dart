import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lapse/features/backup/domain/backup_codec.dart';
import 'package:lapse/features/backup/presentation/backup_actions.dart';
import 'package:lapse/features/settings/presentation/widgets/settings_row.dart';
import 'package:lapse/features/subscriptions/presentation/screens/all_subscriptions_screen.dart';

import '../features/backup/backup_harness.dart';
import '../features/backup/backup_test_data.dart';
import '../features/settings/presentation/settings_test_support.dart';
import '../features/subscriptions/presentation/widgets/list/list_test_support.dart'
    as list;
import '../helpers/fake_subscription_repository.dart';
import '../helpers/fake_system_bridge.dart';
import '../helpers/in_memory_settings_repository.dart';
import '../helpers/pump_app.dart';

List<String> recordAnnouncements(WidgetTester tester) {
  final announcements = <String>[];
  final messenger = tester.binding.defaultBinaryMessenger
    ..setMockDecodedMessageHandler<Object?>(SystemChannels.accessibility, (
      message,
    ) async {
      final event = message! as Map<Object?, Object?>;
      if (event['type'] == 'announce') {
        final data = event['data']! as Map<Object?, Object?>;
        announcements.add(data['message']! as String);
      }
      return null;
    });
  addTearDown(
    () => messenger.setMockDecodedMessageHandler<Object?>(
      SystemChannels.accessibility,
      null,
    ),
  );
  return announcements;
}

void main() {
  testWidgets('saving the reminder time is announced', (tester) async {
    final harness = SettingsHarness();
    await harness.pump(tester, size: const Size(390, 2600));
    final announcements = recordAnnouncements(tester);

    await tester.tap(find.widgetWithText(SettingsRow, 'Reminder time'));
    await settle(tester);
    await tester.tap(find.text('PM'));
    await tester.pump();
    await tester.tap(find.text('Save'));
    await settle(tester);

    expect(announcements, ['Reminder time saved, 09:00 PM']);
  });

  testWidgets('closing the reminder sheet announces nothing', (tester) async {
    final harness = SettingsHarness();
    await harness.pump(tester, size: const Size(390, 2600));
    final announcements = recordAnnouncements(tester);

    await tester.tap(find.widgetWithText(SettingsRow, 'Reminder time'));
    await settle(tester);
    await tester.tap(find.bySemanticsLabel('Close'));
    await settle(tester);

    expect(announcements, isEmpty);
  });

  testWidgets('a finished import is announced', (tester) async {
    await tester.pumpLapse(
      ProviderScope(
        overrides: backupOverrides(
          repository: FakeSubscriptionRepository(),
          bridge: FakeSystemBridge(
            documentToOpen: utf8.encode(BackupCodec.encode(fullBackup())),
          ),
          settings: InMemorySettingsRepository(startingSettings()),
        ),
        child: Consumer(
          builder: (context, ref, _) => TextButton(
            onPressed: () => importBackup(context, ref),
            child: const Text('Import'),
          ),
        ),
      ),
    );
    final announcements = recordAnnouncements(tester);

    await tester.tap(find.text('Import'));
    await settle(tester);
    await tester.tap(find.widgetWithText(InkWell, 'Merge'));
    await settle(tester);

    expect(announcements, ['Import finished. Imported 5 subscriptions']);
  });

  testWidgets('changing the sort is announced', (tester) async {
    tester.usePhoneSize();
    await tester.pumpListScreen(
      const AllSubscriptionsScreen(),
      repository: FakeSubscriptionRepository()
        ..seed(list.seededSubscriptions()),
    );
    final announcements = recordAnnouncements(tester);

    await tester.tap(find.text('Next charge'));
    await tester.pump();
    await tester.pump(list.settle);
    await tester.tap(find.text('Price'));
    await tester.pump();
    await tester.pump(list.settle);

    expect(announcements, ['Sorted by Price']);
  });

  testWidgets('picking the current sort announces nothing', (tester) async {
    tester.usePhoneSize();
    await tester.pumpListScreen(
      const AllSubscriptionsScreen(),
      repository: FakeSubscriptionRepository()
        ..seed(list.seededSubscriptions()),
    );
    final announcements = recordAnnouncements(tester);

    await tester.tap(find.text('Next charge'));
    await tester.pump();
    await tester.pump(list.settle);
    await tester.tap(find.text('Next charge').last);
    await tester.pump();
    await tester.pump(list.settle);

    expect(announcements, isEmpty);
  });
}
