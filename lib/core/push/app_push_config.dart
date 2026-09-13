/// FCM client sync: токен → `push_device_tokens` в Supabase.
///
/// Нужны: Xcode → Push Notifications, APNs key в Firebase Console.
/// Release/TestFlight: `RunnerRelease.entitlements` → `aps-environment=production`.
/// **Симулятор** без APNs → токен пустой; проверка на **реальном iPhone**.
class AppPushConfig {
  AppPushConfig._();

  static const enabled = true;
}
