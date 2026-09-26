import 'package:clover/core/auth/errors/auth_error_code.dart';
import 'package:clover/l10n/app_localizations.dart';

/// User-facing auth error texts resolved by [AuthErrorCode].
abstract final class AuthErrorMessages {
  static String messageFor(
    AuthErrorCode code,
    AppLocalizations l10n, {
    int? retryAfterSeconds,
  }) {
    return switch (code) {
      AuthErrorCode.unknown => l10n.error_auth_unknown,
      AuthErrorCode.checkAuthFailed => l10n.error_auth_check_failed,
      AuthErrorCode.signInCanceled => l10n.error_auth_sign_in_canceled,
      AuthErrorCode.googleIdTokenMissing => l10n.error_auth_google_token_missing,
      AuthErrorCode.googleSignInFailed => l10n.error_auth_google_failed,
      AuthErrorCode.googleClientMisconfigured => l10n.error_auth_google_misconfigured,
      AuthErrorCode.appleIdTokenMissing => l10n.error_auth_apple_token_missing,
      AuthErrorCode.appleSignInFailed => l10n.error_auth_apple_failed,
      AuthErrorCode.appleSignInUnavailable => l10n.error_auth_apple_unavailable,
      AuthErrorCode.supabaseSignInFailed => l10n.error_auth_supabase_sign_in_failed,
      AuthErrorCode.supabaseUserMissing => l10n.error_auth_supabase_user_missing,
      AuthErrorCode.signOutFailed => l10n.error_auth_sign_out_failed,
      AuthErrorCode.networkError => l10n.error_auth_network,
      AuthErrorCode.emailInvalid => l10n.error_auth_email_invalid,
      AuthErrorCode.emailOtpSendFailed => l10n.error_auth_email_otp_send_failed,
      AuthErrorCode.emailOtpVerifyFailed => l10n.error_auth_email_otp_verify_failed,
      AuthErrorCode.emailOtpRateLimited => () {
        final sec = retryAfterSeconds ?? 0;
        if (sec <= 0) {
          return l10n.error_auth_email_otp_rate_limited;
        }
        final m = sec ~/ 60;
        final s = sec % 60;
        final countdown = '$m:${s.toString().padLeft(2, '0')}';
        return l10n.error_auth_email_otp_wait(countdown);
      }(),
      AuthErrorCode.emailAlreadyRegistered => l10n.error_auth_email_already_registered,
      AuthErrorCode.emailNotRegistered => l10n.error_auth_email_not_registered,
      AuthErrorCode.invalidCredentials => l10n.error_auth_invalid_credentials,
      AuthErrorCode.passwordInvalid => l10n.error_auth_password_invalid,
      AuthErrorCode.passwordMismatch => l10n.error_auth_password_mismatch,
      AuthErrorCode.passwordUpdateFailed => l10n.error_auth_password_update_failed,
      AuthErrorCode.identifierInvalid => l10n.error_auth_identifier_invalid,
      AuthErrorCode.hibernateFailed => l10n.error_auth_hibernate_failed,
      AuthErrorCode.hibernateRateLimited => l10n.error_auth_hibernate_rate_limited,
      AuthErrorCode.deleteAccountFailed => l10n.error_auth_delete_account_failed,
    };
  }
}
