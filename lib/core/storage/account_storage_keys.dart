/// Ключи Isar-хранилища: аккаунт vs справочники.
abstract final class AccountStorageKeys {
  AccountStorageKeys._();

  static const authUserId = 'auth_user_id';

  /// Локальный флаг: у userId уже был пароль (после RPC `true` или setPassword).
  /// Префикс `resource_` — не чистится при logout; `false` не кэшируем.
  static String hasPassword(String userId) => 'resource_auth_has_password_$userId';

  /// Epoch-ms последней успешной OTP-отправки на email (синхрон с бэк-cooldown).
  static String otpCooldown(String email) =>
      'resource_auth_otp_cooldown_${email.trim().toLowerCase()}';

  /// Префиксы ключей, которые удаляются при выходе из аккаунта.
  static const accountPrefixes = <String>[
    'auth_',
    'post_new_feed_',
    'post_marker_feed_',
    'post_all_feed_',
    'chat_conversations_',
    'chat_thread_',
    'post_share_following_',
    'post_share_frequent_',
    'post_comments_',
  ];

  /// Префиксы справочников/ресурсов — не трогаем при logout.
  static const resourcePrefixes = <String>[
    'resource_',
    'catalog_',
  ];

  static bool isAccountKey(String key) {
    if (key == authUserId) return true;
    if (resourcePrefixes.any(key.startsWith)) return false;
    return accountPrefixes.any(key.startsWith);
  }
}
