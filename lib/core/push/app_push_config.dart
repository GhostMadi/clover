/// FCM client sync: токен → `push_device_tokens` в Supabase.
///
/// Нужны: Xcode → Push Notifications, APNs key в Firebase Console.
/// Проверка — на реальном устройстве (симулятор без APNs).
class AppPushConfig {
  AppPushConfig._();

  static const enabled = true;
}
