abstract final class Routes {
  static const splash = '/splash';
  static const onboarding = '/onboarding';
  static const permission = '/onboarding/permission';
  static const setup = '/onboarding/setup';

  static const home = '/';
  static const subscriptions = '/subscriptions';
  static const newSubscription = '/subscription/new';
  static String detail(String id) => '/subscription/$id';
  static String edit(String id) => '/subscription/$id/edit';
  static const settings = '/settings';

  static const gallery = '/debug/gallery';
}
