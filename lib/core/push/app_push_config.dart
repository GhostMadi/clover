/// FCM client sync: токен → `push_device_tokens` в Supabase.
///
/// Нужны: Xcode → Push Notifications (`aps-environment` в entitlements),
/// APNs key в Firebase Console.
/// **Симулятор** часто без APNs → токен пустой; проверка на **реальном iPhone**.
class AppPushConfig {
  AppPushConfig._();

  static const enabled = true;
}
