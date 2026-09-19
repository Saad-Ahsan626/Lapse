import 'package:lapse/core/domain/calendar_date.dart';
import 'package:lapse/core/domain/clock.dart';
import 'package:lapse/features/subscriptions/domain/repositories/subscription_repository.dart';
import 'package:lapse/features/subscriptions/domain/services/billing_engine.dart';

class RollOverDueSubscriptions {
  const RollOverDueSubscriptions({
    required SubscriptionRepository repository,
    required BillingEngine engine,
    required Clock clock,
    required IdGenerator newId,
  }) : _repository = repository,
       _engine = engine,
       _clock = clock,
       _newId = newId;

  final SubscriptionRepository _repository;
  final BillingEngine _engine;
  final Clock _clock;
  final IdGenerator _newId;

  Future<int> call() async {
    final now = _clock();
    final today = CalendarDate.fromDateTime(now);
    var updated = 0;
    for (final subscription in await _repository.getAll()) {
      if (!subscription.isActive) continue;
      final result = _engine.rollOver(subscription, today, newId: _newId);
      if (!result.changed) continue;
      await _repository.applyRollOver(
        result.subscription.copyWith(updatedAt: now.toUtc()),
        result.charges,
      );
      updated++;
    }
    return updated;
  }
}
