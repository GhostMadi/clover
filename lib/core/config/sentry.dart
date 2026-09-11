/// Sentry client config (DSN публичный для SDK — не service_role).
///
/// Org: `clover-so` · Project: `flutter`
class SentryConfig {
  const SentryConfig._();

  static const dsn =
      'https://a8344afe4b1aea49568ade573dff8256@o4512063594168320.ingest.de.sentry.io/4512063598297168';

  /// Можно переопределить: `--dart-define=SENTRY_DSN=...`
  static String get resolvedDsn {
    const fromDefine = String.fromEnvironment('SENTRY_DSN');
    if (fromDefine.isNotEmpty) return fromDefine;
    return dsn;
  }
}
