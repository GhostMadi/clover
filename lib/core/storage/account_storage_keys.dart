/// Ключи Isar-хранилища: аккаунт vs справочники.
abstract final class AccountStorageKeys {
  AccountStorageKeys._();

  static const authUserId = 'auth_user_id';

  /// Префиксы ключей, которые удаляются при выходе из аккаунта.
  static const accountPrefixes = <String>[
    'auth_',
    'post_new_feed_',
    'post_marker_feed_',
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
