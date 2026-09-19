import 'package:lapse/core/domain/clock.dart';
import 'package:lapse/core/errors/validation_exception.dart';
import 'package:lapse/features/subscriptions/domain/entities/subscription.dart';
import 'package:lapse/features/subscriptions/domain/repositories/subscription_repository.dart';
import 'package:lapse/features/subscriptions/domain/validation/subscription_field.dart';
import 'package:lapse/features/subscriptions/domain/validation/subscription_validator.dart';

class SaveSubscription {
  const SaveSubscription({
    required SubscriptionRepository repository,
    required SubscriptionValidator validator,
    required Clock clock,
    required IdGenerator newId,
  }) : _repository = repository,
       _validator = validator,
       _clock = clock,
       _newId = newId;

  final SubscriptionRepository _repository;
  final SubscriptionValidator _validator;
  final Clock _clock;
  final IdGenerator _newId;

  Future<Subscription> call(Subscription input) async {
    final existing = input.isUnsaved
        ? null
        : await _repository.getById(input.id);

    final normalized = input.copyWith(
      name: input.name.trim(),
      category: _blankToNull(input.category),
      cancelUrl: _blankToNull(input.cancelUrl),
      paymentMethod: _blankToNull(input.paymentMethod),
      notes: _blankToNull(input.notes),
      reminderOffsets: _normalizeOffsets(input.reminderOffsets),
      anchorDay:
          existing != null && existing.nextBillingDate == input.nextBillingDate
          ? existing.anchorDay
          : input.nextBillingDate.day,
    );

    final errors = _validator.validate(normalized);
    if (errors.isNotEmpty) {
      throw ValidationException<SubscriptionField>(errors);
    }

    final now = _clock().toUtc();
    final saved = normalized.copyWith(
      id: normalized.isUnsaved ? _newId() : normalized.id,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );
    await _repository.upsert(saved);
    return saved;
  }

  static String? _blankToNull(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  static List<int> _normalizeOffsets(List<int> offsets) =>
      offsets.toSet().toList()..sort((a, b) => b.compareTo(a));
}
