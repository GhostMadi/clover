import 'package:clover/core/auth/errors/auth_error_code.dart';
import 'package:clover/core/auth/errors/auth_failure.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Maps provider exceptions to internal [AuthErrorCode].
abstract final class AuthErrorMapper {
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
      final statusCode = int.tryParse(error.statusCode ?? '');
      if (statusCode != null && statusCode >= 500) {
        return AuthErrorCode.networkError;
      }
      return AuthErrorCode.supabaseSignInFailed;
    }

    return AuthErrorCode.unknown;
  }
}
