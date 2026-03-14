/// Application-level constants used across all layers.
class AppConstants {
  AppConstants._();

  static const String appName = 'Aurora Ledger';
  static const String appVersion = '0.1.0';
  static const int minAliasLength = 1;
  static const int maxAliasLength = 30;

  /// Max groups per identity to prevent unbounded DB growth.
  static const int maxGroupsPerIdentity = 50;

  /// Hours before soft replica warning nudge.
  static const int replicaWarnThresholdHours = 24;

  /// Hours before ADD_EXPENSE is blocked (min-replica enforcement).
  static const int replicaBlockThresholdHours = 72;

  static const String groupCodePrefix = 'AURORA';
  static const int groupCodeSegmentLength = 4;

  // TODO: Expand as needed; groups are single-currency by design.
  static const List<String> supportedCurrencies = [
    'GBP', 'USD', 'EUR', 'JPY', 'AUD', 'CAD', 'CHF', 'CNY', 'INR', 'SGD',
  ];
}
