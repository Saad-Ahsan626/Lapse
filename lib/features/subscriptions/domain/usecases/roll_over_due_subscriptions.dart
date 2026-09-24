import 'package:lapse/core/domain/calendar_date.dart';
import 'package:lapse/core/domain/clock.dart';
import 'package:lapse/features/subscriptions/domain/repositories/roll_over_write.dart';
import 'package:lapse/features/subscriptions/domain/repositories/subscription_repository.dart';
import 'package:lapse/features/subscriptions/domain/services/billing_engine.dart';

class RollOverDueSubscriptions {
  RollOverDueSubscriptions({
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
  Future<void> _tail = Future<void>.value();

  Future<int> call() {
    final run = _tail.then((_) => _run());
    _tail = run.then<void>((_) {}, onError: (Object _) {});
    return run;
  }

  Future<int> _run() async {
    final now = _clock();
    final today = CalendarDate.fromDateTime(now);
    final writes = <RollOverWrite>[];
    for (final subscription in await _repository.getAll()) {
      if (!subscription.isActive) continue;
      try {
        final result = _engine.rollOver(subscription, today, newId: _newId);
        if (!result.changed) continue;
        writes.add((
          result.subscription.copyWith(updatedAt: now.toUtc()),
          result.charges,
          subscription.nextBillingDate,
        ));
      } on Object {
        continue;
      }
    }
    if (writes.isEmpty) return 0;
    return _repository.applyRollOvers(writes);
  }
}
