import 'package:clover/core/auth/errors/auth_error_code.dart';
import 'package:clover/core/auth/models/user_model.dart';

sealed class AuthState {
  const AuthState();
}

final class AuthInitial extends AuthState {
  const AuthInitial();
}

final class AuthLoading extends AuthState {
  const AuthLoading();
}

final class Authenticated extends AuthState {
  const Authenticated(this.user);

  final UserModel user;
}

final class Unauthenticated extends AuthState {
  const Unauthenticated();
}

/// OTP sent for [AuthOtpPurpose.register] or [AuthOtpPurpose.resetPassword].
final class AuthEmailOtpSent extends AuthState {
  const AuthEmailOtpSent({
    required this.email,
    required this.purpose,
    this.resumedWithoutResend = false,
  });

  final String email;
  final AuthOtpPurpose purpose;

  /// Кулдаун ещё идёт: письмо не слали снова, только вернули на ввод кода.
  final bool resumedWithoutResend;
}

/// Session after OTP; password must be set before [Authenticated].
final class AuthPasswordSetupRequired extends AuthState {
  const AuthPasswordSetupRequired({required this.email, required this.purpose});

  final String email;
  final AuthOtpPurpose purpose;
}

final class AuthError extends AuthState {
  const AuthError(this.code, {this.retryAfterSeconds});

  final AuthErrorCode code;
  final int? retryAfterSeconds;
}

enum AuthOtpPurpose { register, resetPassword }
