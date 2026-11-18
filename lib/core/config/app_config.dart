/// Build-time configuration.
///
/// Values are injected with `--dart-define-from-file=env/<env>.json`
/// (see `env/example.json`). Nothing secret may ever live here: everything
/// compiled into the app can be extracted. Secret keys belong on the server
/// (Cloud Functions secrets in the customer repo).
abstract final class AppConfig {
  /// Shop brand, shown in the wordmark.
  static const String appName = 'Your Shop';

  /// Window and task-switcher title.
  static const String title = 'Your Shop Admin';

  /// `dev`, `staging` or `prod`.
  static const String environment = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'dev',
  );

  static bool get isProduction => environment == 'prod';

  static const String currency = String.fromEnvironment(
    'CURRENCY',
    defaultValue: 'BDT',
  );

  static const String currencySymbol = String.fromEnvironment(
    'CURRENCY_SYMBOL',
    defaultValue: 'Tk',
  );

  /// Base URL of the deployed Cloud Functions, e.g.
  /// `https://asia-southeast1-<project>.cloudfunctions.net`. Needed for
  /// admin actions that run on the server (cancel with restock and refund).
  static const String functionsBaseUrl = String.fromEnvironment(
    'FUNCTIONS_BASE_URL',
  );

  static bool get isBackendConfigured => functionsBaseUrl.isNotEmpty;

  /// Products at or below this stock count are "low stock".
  static const int lowStockThreshold = int.fromEnvironment(
    'LOW_STOCK_THRESHOLD',
    defaultValue: 5,
  );
}
