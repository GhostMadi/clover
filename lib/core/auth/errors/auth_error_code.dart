/// Internal auth error codes. UI resolves human-readable text via [AuthErrorMessages].
enum AuthErrorCode {
  unknown('auth_unknown'),
  checkAuthFailed('auth_check_failed'),
  signInCanceled('auth_sign_in_canceled'),
  googleIdTokenMissing('auth_google_id_token_missing'),
  googleSignInFailed('auth_google_sign_in_failed'),
  googleClientMisconfigured('auth_google_client_misconfigured'),
  supabaseSignInFailed('auth_supabase_sign_in_failed'),
  supabaseUserMissing('auth_supabase_user_missing'),
  signOutFailed('auth_sign_out_failed'),
  networkError('auth_network_error');

  const AuthErrorCode(this.value);

  final String value;
}
