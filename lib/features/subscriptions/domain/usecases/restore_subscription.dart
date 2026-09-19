import 'package:lapse/core/domain/calendar_date.dart';
import 'package:lapse/core/domain/clock.dart';
import 'package:lapse/features/subscriptions/domain/entities/subscription.dart';
import 'package:lapse/features/subscriptions/domain/entities/subscription_status.dart';
import 'package:lapse/features/subscriptions/domain/repositories/subscription_repository.dart';
import 'package:lapse/features/subscriptions/domain/services/billing_engine.dart';

class RestoreSubscription {
  const RestoreSubscription({
    required SubscriptionRepository repository,
    required BillingEngine engine,
    required Clock clock,
  }) : _repository = repository,
       _engine = engine,
       _clock = clock;

  final SubscriptionRepository _repository;
  final BillingEngine _engine;
  final Clock _clock;

  Future<Subscription> call(String id) async {
    final subscription = await _repository.getById(id);
    if (subscription == null) {
      throw StateError('Subscription $id not found');
    }
    final now = _clock();
    final reactivated = subscription.copyWith(
      status: SubscriptionStatus.active,
      cancelledAt: null,
      updatedAt: now.toUtc(),
    );
    final caughtUp = _engine
        .rollOver(
          reactivated,
          CalendarDate.fromDateTime(now),
          newId: () => '',
        )
        .subscription;
    await _repository.upsert(caughtUp);
    return caughtUp;
  }
}
