import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lapse/features/backup/domain/backup_codec.dart';
import 'package:lapse/features/backup/domain/backup_data.dart';
import 'package:lapse/features/backup/domain/backup_format_exception.dart';

import '../backup_test_data.dart';

Map<String, Object?> _json(BackupData data) =>
    jsonDecode(BackupCodec.encode(data)) as Map<String, Object?>;

String _message(Object? json) {
  try {
    BackupCodec.decode(json is String ? json : jsonEncode(json));
  } on BackupFormatException catch (error) {
    return error.message;
  }
  fail('Expected a BackupFormatException');
}

void main() {
  group('round trip', () {
    test('keeps every field, including nulls and special cases', () {
      final data = fullBackup();

      final decoded = BackupCodec.decode(BackupCodec.encode(data));

      expect(decoded, data);
      expect(decoded.subscriptions.first, fullSubscription());
      expect(decoded.subscriptions.first.createdAt.isUtc, isTrue);
      expect(decoded.subscriptions[1].customDays, 45);
      expect(decoded.subscriptions[1].isTrial, isTrue);
      expect(decoded.subscriptions[2].cancelledAt, isNotNull);
      expect(decoded.subscriptions.last.catalogKey, isNull);
      expect(decoded.settings, settingsFixture());
    });

    test('keeps a missing user name as null', () {
      final data = BackupData(
        exportedAt: backupExportedAt,
        settings: settingsFixture(userName: null),
        subscriptions: const [],
        charges: const [],
      );

      expect(BackupCodec.decode(BackupCodec.encode(data)), data);
    });

    test('is stable and pretty printed', () {
      final text = BackupCodec.encode(fullBackup());

      expect(text, BackupCodec.encode(fullBackup()));
      expect(text, startsWith('{\n  "app": "lapse",\n  "schemaVersion": 1,'));
      expect(text, endsWith('}\n'));
    });

    test('ignores a leading byte order mark', () {
      final text = '\u{FEFF}${BackupCodec.encode(fullBackup())}';

      expect(BackupCodec.decode(text), fullBackup());
    });
  });

  test('JSON shape: keys in order, money and charge objects', () {
    final json = _json(fullBackup());

    expect(json.keys.toList(), [
      'app',
      'schemaVersion',
      'exportedAt',
      'settings',
      'subscriptions',
      'charges',
    ]);
    expect(json['exportedAt'], '2026-09-21T06:30:15.123Z');
    expect(json['settings'], {
      'defaultCurrency': 'USD',
      'reminderMinutes': 1230,
      'defaultReminderOffsets': [3, 0],
      'themeMode': 'dark',
      'userName': 'Saad',
    });
    final subscription =
        (json['subscriptions']! as List<Object?>).first!
            as Map<String, Object?>;
    expect(subscription.keys.toList(), [
      'id',
      'name',
      'catalogKey',
      'category',
      'price',
      'period',
      'customDays',
      'anchorDay',
      'startDate',
      'nextBillingDate',
      'isTrial',
      'reminderOffsets',
      'cancelUrl',
      'paymentMethod',
      'notes',
      'status',
      'cancelledAt',
      'snoozedUntil',
      'createdAt',
      'updatedAt',
    ]);
    expect(subscription['price'], {'minor': 155000, 'currency': 'PKR'});
    expect(subscription['startDate'], '2025-01-31');
    expect(subscription['cancelledAt'], isNull);
    expect(subscription['snoozedUntil'], '2026-09-28T04:00:00.000Z');
    expect((json['charges']! as List<Object?>).first, {
      'id': 'c-1',
      'subscriptionId': 'sub-full',
      'amount': {'minor': 155000, 'currency': 'PKR'},
      'chargedOn': '2026-07-31',
    });
  });

  group('validation', () {
    Map<String, Object?> valid() => _json(fullBackup());

    Map<String, Object?> withSubscription(
      int index,
      void Function(Map<String, Object?> sub) change,
    ) {
      final json = valid();
      final subs = json['subscriptions']! as List<Object?>;
      change(subs[index]! as Map<String, Object?>);
      return json;
    }

    Map<String, Object?> withCharge(
      int index,
      void Function(Map<String, Object?> charge) change,
    ) {
      final json = valid();
      final charges = json['charges']! as List<Object?>;
      change(charges[index]! as Map<String, Object?>);
      return json;
    }

    test('rejects text that is not JSON', () {
      expect(
        _message('not json {'),
        const BackupFormatException.notJson().message,
      );
    });

    test('rejects JSON from another app', () {
      final wrongApp = const BackupFormatException.wrongApp().message;
      expect(_message(valid()..['app'] = 'other'), wrongApp);
      expect(_message(valid()..remove('app')), wrongApp);
      expect(_message([1, 2]), wrongApp);
    });

    test('rejects a newer schema version', () {
      expect(
        _message(valid()..['schemaVersion'] = BackupCodec.schemaVersion + 1),
        const BackupFormatException.newerVersion().message,
      );
    });

    test('rejects a missing schema version', () {
      expect(
        _message(valid()..remove('schemaVersion')),
        const BackupFormatException.missingVersion().message,
      );
    });

    test('rejects a bad export date', () {
      expect(
        _message(valid()..['exportedAt'] = 'yesterday'),
        const BackupFormatException.badExportDate().message,
      );
    });

    test('rejects bad settings', () {
      final bad = const BackupFormatException.badSettings().message;
      expect(_message(valid()..remove('settings')), bad);
      final theme = valid();
      (theme['settings']! as Map<String, Object?>)['themeMode'] = 'neon';
      expect(_message(theme), bad);
      final time = valid();
      (time['settings']! as Map<String, Object?>)['reminderMinutes'] = 1440;
      expect(_message(time), bad);
    });

    test('rejects missing lists', () {
      expect(
        _message(valid()..remove('charges')),
        const BackupFormatException.badList().message,
      );
    });

    test('names the first bad subscription', () {
      expect(
        _message(withSubscription(1, (s) => s['period'] = 'daily')),
        '“Gym” in this backup is invalid.',
      );
      expect(
        _message(
          withSubscription(0, (s) => s['nextBillingDate'] = '2026-02-30'),
        ),
        '“Netflix Standard” in this backup is invalid.',
      );
      expect(
        _message(withSubscription(2, (s) => s.remove('price'))),
        '“Adobe” in this backup is invalid.',
      );
      expect(
        _message(withSubscription(1, (s) => s['customDays'] = null)),
        '“Gym” in this backup is invalid.',
      );
      expect(
        _message(withSubscription(3, (s) => s['updatedAt'] = 3)),
        '“Crunchyroll” in this backup is invalid.',
      );
    });

    test('rejects custom days outside 1 to 9999', () {
      const gym = '“Gym” in this backup is invalid.';
      expect(_message(withSubscription(1, (s) => s['customDays'] = 0)), gym);
      expect(
        _message(withSubscription(1, (s) => s['customDays'] = 10000)),
        gym,
      );
      expect(
        _message(withSubscription(1, (s) => s['customDays'] = 1 << 40)),
        gym,
      );
      final edge = withSubscription(1, (s) => s['customDays'] = 9999);
      expect(
        BackupCodec.decode(jsonEncode(edge)).subscriptions[1].customDays,
        9999,
      );
    });

    test('rejects years after 9999', () {
      const netflix = '“Netflix Standard” in this backup is invalid.';
      expect(
        _message(
          withSubscription(0, (s) => s['createdAt'] = '+10000-01-01T00:00:00Z'),
        ),
        netflix,
      );
      expect(
        _message(
          withSubscription(0, (s) => s['snoozedUntil'] = '+12026-01-01T00:00Z'),
        ),
        netflix,
      );
      expect(
        _message(
          withSubscription(0, (s) => s['nextBillingDate'] = '+10000-01-01'),
        ),
        netflix,
      );
    });

    test('uses the position when the name is missing', () {
      expect(
        _message(withSubscription(4, (s) => s.remove('name'))),
        'Subscription 5 in this backup is invalid.',
      );
    });

    test('rejects duplicate subscriptions', () {
      expect(
        _message(withSubscription(1, (s) => s['id'] = 'sub-full')),
        '“Gym” appears twice in this backup.',
      );
    });

    test('rejects a payment for an unknown subscription', () {
      expect(
        _message(withCharge(1, (c) => c['subscriptionId'] = 'ghost')),
        'Payment 2 in this backup is invalid.',
      );
    });

    test('rejects duplicate or malformed payments', () {
      expect(
        _message(withCharge(2, (c) => c['id'] = 'c-1')),
        'Payment 3 in this backup is invalid.',
      );
      expect(
        _message(withCharge(0, (c) => c.remove('amount'))),
        'Payment 1 in this backup is invalid.',
      );
    });
  });
}
