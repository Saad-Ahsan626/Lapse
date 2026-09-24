import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lapse/features/subscriptions/domain/entities/charge.dart';
import 'package:lapse/features/subscriptions/presentation/providers/subscription_list_providers.dart';
import 'package:lapse/features/subscriptions/presentation/providers/subscription_service_providers.dart';

import '../../../../helpers/fake_subscription_repository.dart';
import '../../../../helpers/subscription_fixtures.dart';

class CountingSubscriptionRepository extends FakeSubscriptionRepository {
  final Map<String, int> chargeQueries = {};

  @override
  Future<List<Charge>> chargesFor(String subscriptionId) {
    chargeQueries[subscriptionId] = (chargeQueries[subscriptionId] ?? 0) + 1;
    return super.chargesFor(subscriptionId);
  }
}

void main() {
  test(
    'chargesProvider re-queries only when its subscription changes',
    () async {
      final repository = CountingSubscriptionRepository()
        ..seed([
          subscriptionFixture(id: 'a', name: 'Netflix'),
          subscriptionFixture(id: 'b', name: 'Spotify'),
        ]);
      final container = ProviderContainer(
        overrides: [
          subscriptionRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);
      container.listen(chargesProvider('a'), (_, _) {});
      await container.read(subscriptionsProvider.future);
      await pumpEventQueue();
      final initial = repository.chargeQueries['a']!;

      await repository.upsert(
        subscriptionFixture(id: 'b', name: 'Spotify', priceMinor: 1),
      );
      await pumpEventQueue();
      expect(repository.chargeQueries['a'], initial);

      await repository.upsert(
        subscriptionFixture(id: 'a', name: 'Netflix', priceMinor: 1),
      );
      await pumpEventQueue();
      await container.read(chargesProvider('a').future);
      expect(repository.chargeQueries['a'], initial + 1);
    },
  );
}
