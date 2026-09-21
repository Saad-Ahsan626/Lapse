abstract final class Routes {
  static const splash = '/splash';
  static const onboarding = '/onboarding';
  static const permission = '/onboarding/permission';
  static const setup = '/onboarding/setup';

  static const home = '/';
  static const subscriptions = '/subscriptions';
  static String subscriptionsTab(String tab) =>
      Uri(path: subscriptions, queryParameters: {'tab': tab}).toString();
  static const newSubscription = '/subscription/new';
  static String newSubscriptionFor({String? serviceKey, String? name}) => Uri(
    path: newSubscription,
    queryParameters: {'service': ?serviceKey, 'name': ?name},
  ).toString();
  static String detail(String id) => '/subscription/$id';
  static String edit(String id) => '/subscription/$id/edit';
  static const settings = '/settings';
  static const remindersPermission = '/reminders/permission';

  static const gallery = '/debug/gallery';
  static const dataInspector = '/debug/data';
}
