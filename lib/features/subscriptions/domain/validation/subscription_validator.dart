import 'package:lapse/features/subscriptions/domain/entities/billing_period.dart';
import 'package:lapse/features/subscriptions/domain/entities/subscription.dart';
import 'package:lapse/features/subscriptions/domain/validation/subscription_field.dart';

class SubscriptionValidator {
  const SubscriptionValidator();

  static const maxReminderOffset = 30;

  Map<SubscriptionField, String> validate(Subscription subscription) {
    final errors = <SubscriptionField, String>{};

    if (subscription.name.trim().isEmpty) {
      errors[SubscriptionField.name] = 'Enter a name';
    }
    if (!subscription.price.isPositive) {
      errors[SubscriptionField.price] = 'Enter a price';
    }
    if (subscription.period == BillingPeriod.customDays) {
      final days = subscription.customDays;
      if (days == null || days < 1) {
        errors[SubscriptionField.customDays] = 'Enter how many days';
      }
    }
    if (subscription.anchorDay < 1 || subscription.anchorDay > 31) {
      errors[SubscriptionField.anchorDay] = 'Day must be between 1 and 31';
    }
    if (subscription.reminderOffsets.any(
      (d) => d < 0 || d > maxReminderOffset,
    )) {
      errors[SubscriptionField.reminderOffsets] =
          'Reminders can be 0 to $maxReminderOffset days before';
    }
    final url = subscription.cancelUrl;
    if (url != null && url.isNotEmpty && !_isWebUrl(url)) {
      errors[SubscriptionField.cancelUrl] =
          'Enter a link starting with https://';
    }
    if (subscription.nextBillingDate.isBefore(subscription.startDate)) {
      errors[SubscriptionField.nextBillingDate] =
          'The next charge cannot be before the start date';
    }

    return errors;
  }

  bool _isWebUrl(String value) {
    final uri = Uri.tryParse(value.trim());
    return uri != null &&
        (uri.scheme == 'https' || uri.scheme == 'http') &&
        uri.host.isNotEmpty;
  }
}
