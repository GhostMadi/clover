import 'package:clover/core/auth/errors/auth_error_code.dart';
import 'package:clover/core/auth/errors/auth_failure.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Maps provider exceptions to internal [AuthErrorCode].
abstract final class AuthErrorMapper {
  /// Refresh token отозван / не найден — локальную сессию нужно сбросить.
  static bool isInvalidRefreshToken(Object error) {
    if (error is! AuthException) return false;
    final message = error.message.toLowerCase();
    final code = (error.code ?? '').toLowerCase();
    return code == 'refresh_token_not_found' ||
        message.contains('refresh_token_not_found') ||
        message.contains('invalid refresh token');
  }

  static AuthErrorCode resolve(Object error) {
    if (error is AuthFailure) return error.code;

    if (error is GoogleSignInException) {
      return switch (error.code) {
        GoogleSignInExceptionCode.canceled => AuthErrorCode.signInCanceled,
        GoogleSignInExceptionCode.clientConfigurationError ||
        GoogleSignInExceptionCode.providerConfigurationError =>
          AuthErrorCode.googleClientMisconfigured,
        GoogleSignInExceptionCode.interrupted ||
        GoogleSignInExceptionCode.uiUnavailable ||
        GoogleSignInExceptionCode.userMismatch ||
        GoogleSignInExceptionCode.unknownError =>
          AuthErrorCode.googleSignInFailed,
      };
    }

    if (error is AuthException) {
      if (isInvalidRefreshToken(error)) {
        return AuthErrorCode.checkAuthFailed;
      }
      final message = error.message.toLowerCase();
      if (message.contains('rate limit') ||
          message.contains('over_email_send_rate_limit') ||
          message.contains('too many otp') ||
          message.contains('retry in')) {
        return AuthErrorCode.emailOtpRateLimited;
      }
      final statusCode = int.tryParse(error.statusCode ?? '');
      if (statusCode == 429) {
        return AuthErrorCode.emailOtpRateLimited;
      }
      if (message.contains('invalid login credentials') ||
          message.contains('invalid_credentials') ||
          message.contains('email not confirmed')) {
        return AuthErrorCode.invalidCredentials;
      }
      if (message.contains('user already registered') || message.contains('already been registered')) {
        return AuthErrorCode.emailAlreadyRegistered;
      }
      if (message.contains('otp') || message.contains('token') || message.contains('expired')) {
        return AuthErrorCode.emailOtpVerifyFailed;
      }
      if (statusCode != null && statusCode >= 500) {
        return AuthErrorCode.networkError;
      }
      return AuthErrorCode.supabaseSignInFailed;
    }

    return AuthErrorCode.unknown;
  }

  /// Parses `Retry in 123 seconds` from Send Email Hook / Auth errors.
  static int? retryAfterSecondsFromMessage(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final match = RegExp(r'retry in\s+(\d+)\s*seconds?', caseSensitive: false).firstMatch(raw);
    if (match == null) return null;
    final n = int.tryParse(match.group(1) ?? '');
    if (n == null || n <= 0) return null;
    return n;
  }
}
