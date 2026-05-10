class RouteName {
  RouteName._();

  static const String login = '/login';
  static const String dashboard = '/';
  static const String files = '/files';
  static const String analytics = '/analytics';
  static const String duplicates = '/duplicates';
  static const String accounts = '/accounts';
  static const String settings = '/settings';
  static const String accessBucketFiles = '/access-bucket';

  static String accountDetail(String accountId) => '/accounts/$accountId';
}

class RouteExtra {
  RouteExtra._();

  static const String accessBucket = 'bucket';
  static const String accountId = 'accountId';
}
