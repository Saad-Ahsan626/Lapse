import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lapse/app/router/routes.dart';
import 'package:lapse/features/reminders/application/reminder_providers.dart';
import 'package:lapse/features/reminders/data/notification_launch.dart';

Future<NotificationLaunch?> bootstrapReminders(
  ProviderContainer container, {
  bool configureTimezone = true,
}) async {
  try {
    if (configureTimezone) await container.read(configureTimezoneProvider)();
    final gateway = container.read(notificationGatewayProvider);
    await gateway.initialize(
      onTap: (tap) => unawaited(
        container.read(notificationTapHandlerProvider).handle(tap),
      ),
    );
    return await gateway.launchDetails();
  } on Object {
    return null;
  }
}

String initialLocationFor(NotificationLaunch? launch) =>
    launch == null ? Routes.splash : Routes.detail(launch.tap.subscriptionId);
