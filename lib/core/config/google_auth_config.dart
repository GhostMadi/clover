/// Native Google Sign-In для iOS + Supabase signInWithIdToken.
///
/// Supabase Dashboard → Auth → Google:
/// - Client IDs: iOS client ID ([iosClientId])
/// - Client Secret: пусто
/// - Skip nonce checks: включено
abstract final class GoogleAuthConfig {
  GoogleAuthConfig._();

  /// iOS OAuth client (Info.plist GIDClientID). Bundle ID: clover.mobile.com
  static const iosClientId =
      '1041927738445-mvr2koskarj7c1rg82avsbmgsk8ih91h.apps.googleusercontent.com';
}
