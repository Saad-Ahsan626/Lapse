import 'package:lapse/features/subscriptions/domain/repositories/subscription_repository.dart';

class DeleteSubscription {
  const DeleteSubscription({required SubscriptionRepository repository})
    : _repository = repository;

  final SubscriptionRepository _repository;

  Future<void> call(String id) => _repository.delete(id);
}
