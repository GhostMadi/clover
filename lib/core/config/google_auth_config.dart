/// Native Google Sign-In → Supabase [signInWithIdToken].
///
/// OAuth clients — один Google Cloud project (`supple-folder-500014-g4` /
/// prefix `1041927738445`):
/// - **Web** («Clover Web Client») → [webClientId] + secret в Supabase
/// - **iOS** → [iosClientId] (Info.plist `GIDClientID`)
/// - **Android** → package `clover.mobile.com` + SHA-1 (debug/upload)
///
/// Supabase → Auth → Providers → Google:
/// - Client ID / Secret = **Web**
/// - Authorized Client IDs = iOS + Android (через запятую), если поле есть
/// - Skip nonce checks: **вкл** (native idToken)
abstract final class GoogleAuthConfig {
  GoogleAuthConfig._();

  /// Web OAuth client — audience idToken / `serverClientId` на всех платформах.
  static const webClientId =
      '1041927738445-5ki8al5rpub3fbnvm0q64q9k8s5gjajs.apps.googleusercontent.com';

  /// iOS OAuth client (Info.plist GIDClientID). Bundle ID: clover.mobile.com
  static const iosClientId =
      '1041927738445-mvr2koskarj7c1rg82avsbmgsk8ih91h.apps.googleusercontent.com';
}
