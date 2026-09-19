import 'package:flutter_test/flutter_test.dart';
import 'package:lapse/core/domain/calendar_date.dart';
import 'package:lapse/core/domain/money.dart';
import 'package:lapse/features/subscriptions/domain/entities/billing_period.dart';
import 'package:lapse/features/subscriptions/domain/entities/subscription.dart';
import 'package:lapse/features/subscriptions/domain/validation/subscription_field.dart';
import 'package:lapse/features/subscriptions/domain/validation/subscription_validator.dart';

import '../../../../helpers/subscription_fixtures.dart';

void main() {
  const validator = SubscriptionValidator();
  final valid = subscriptionFixture(cancelUrl: 'https://example.com/cancel');

  Set<SubscriptionField> fieldsWithErrors(Subscription subscription) =>
      validator.validate(subscription).keys.toSet();

  test('a complete subscription has no errors', () {
    expect(validator.validate(valid), isEmpty);
  });

  test('name must not be blank', () {
    expect(fieldsWithErrors(valid.copyWith(name: '   ')), {
      SubscriptionField.name,
    });
  });

  test('price must be above zero', () {
    expect(fieldsWithErrors(valid.copyWith(price: const Money(0, 'PKR'))), {
      SubscriptionField.price,
    });
  });

  test('custom period needs at least one day', () {
    final custom = valid.copyWith(period: BillingPeriod.customDays);
    expect(fieldsWithErrors(custom), {SubscriptionField.customDays});
    expect(fieldsWithErrors(custom.copyWith(customDays: 0)), {
      SubscriptionField.customDays,
    });
    expect(validator.validate(custom.copyWith(customDays: 14)), isEmpty);
  });

  test('anchor day is 1–31', () {
    expect(fieldsWithErrors(valid.copyWith(anchorDay: 0)), {
      SubscriptionField.anchorDay,
    });
    expect(fieldsWithErrors(valid.copyWith(anchorDay: 32)), {
      SubscriptionField.anchorDay,
    });
  });

  test('reminder offsets are 0–30 days', () {
    expect(fieldsWithErrors(valid.copyWith(reminderOffsets: [31])), {
      SubscriptionField.reminderOffsets,
    });
    expect(fieldsWithErrors(valid.copyWith(reminderOffsets: [-1])), {
      SubscriptionField.reminderOffsets,
    });
    expect(
      validator.validate(valid.copyWith(reminderOffsets: [0, 30])),
      isEmpty,
    );
  });

  test('cancel link must be a web address', () {
    expect(fieldsWithErrors(valid.copyWith(cancelUrl: 'netflix.com')), {
      SubscriptionField.cancelUrl,
    });
    expect(fieldsWithErrors(valid.copyWith(cancelUrl: 'ftp://x.com')), {
      SubscriptionField.cancelUrl,
    });
    expect(validator.validate(valid.copyWith(cancelUrl: '')), isEmpty);
    expect(validator.validate(valid.copyWith(cancelUrl: null)), isEmpty);
  });

  test('next charge cannot be before the start date', () {
    expect(
      fieldsWithErrors(
        valid.copyWith(
          startDate: CalendarDate(2026, 10, 2),
          nextBillingDate: CalendarDate(2026, 10, 1),
        ),
      ),
      {SubscriptionField.nextBillingDate},
    );
  });

  test('every error comes with a message', () {
    final errors = validator.validate(
      valid.copyWith(name: '', price: const Money(0, 'PKR')),
    );
    expect(errors.values.every((m) => m.isNotEmpty), isTrue);
  });
}
