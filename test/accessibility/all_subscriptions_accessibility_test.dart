import 'package:lapse/features/subscriptions/presentation/providers/subscription_tab.dart';
import 'package:lapse/features/subscriptions/presentation/screens/all_subscriptions_screen.dart';

import '../features/subscriptions/presentation/widgets/list/list_test_support.dart';
import '../helpers/fake_subscription_repository.dart';
import 'a11y_test_support.dart';

void main() {
  for (final tab in SubscriptionTab.values) {
    accessibilityTests('all subscriptions ${tab.name}', (
      tester,
      brightness,
      scale,
    ) async {
      tester.usePhoneSize();
      await tester.pumpListScreen(
        AllSubscriptionsScreen(initialTab: tab),
        repository: FakeSubscriptionRepository()..seed(seededSubscriptions()),
        brightness: brightness,
        textScale: scale,
      );
      await frames(tester, 6);
    });
  }
}
