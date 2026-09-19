import 'package:lapse/core/domain/clock.dart';
import 'package:lapse/core/domain/money.dart';
import 'package:lapse/features/subscriptions/domain/entities/subscription_status.dart';
import 'package:lapse/features/subscriptions/domain/repositories/subscription_repository.dart';
import 'package:lapse/features/subscriptions/domain/services/billing_engine.dart';

class MarkCancelled {
  const MarkCancelled({
    required SubscriptionRepository repository,
    required BillingEngine engine,
    required Clock clock,
  }) : _repository = repository,
       _engine = engine,
       _clock = clock;

  final SubscriptionRepository _repository;
  final BillingEngine _engine;
  final Clock _clock;

  Future<Money> call(String id) async {
    final subscription = await _repository.getById(id);
    if (subscription == null) {
      throw StateError('Subscription $id not found');
    }
    final now = _clock().toUtc();
    await _repository.upsert(
      subscription.copyWith(
        status: SubscriptionStatus.cancelled,
        cancelledAt: now,
        snoozedUntil: null,
        updatedAt: now,
      ),
    );
    return _engine.yearlyCost(subscription);
  }
}
