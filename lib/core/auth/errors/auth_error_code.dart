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
  networkError('auth_network_error'),
  emailInvalid('auth_email_invalid'),
  emailOtpSendFailed('auth_email_otp_send_failed'),
  emailOtpVerifyFailed('auth_email_otp_verify_failed'),
  emailOtpRateLimited('auth_email_otp_rate_limited'),
  emailAlreadyRegistered('auth_email_already_registered'),
  emailNotRegistered('auth_email_not_registered'),
  invalidCredentials('auth_invalid_credentials'),
  passwordInvalid('auth_password_invalid'),
  passwordMismatch('auth_password_mismatch'),
  passwordUpdateFailed('auth_password_update_failed'),
  identifierInvalid('auth_identifier_invalid');

  const AuthErrorCode(this.value);

  final String value;
}
