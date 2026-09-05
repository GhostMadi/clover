import 'package:clover/core/auth/cubit/auth_state.dart';
import 'package:clover/core/auth/errors/auth_error_code.dart';
import 'package:clover/core/auth/errors/auth_error_mapper.dart';
import 'package:clover/core/auth/errors/auth_failure.dart';
import 'package:clover/core/auth/repositories/auth_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

@injectable
class AuthCubit extends Cubit<AuthState> {
  AuthCubit(this._repository) : super(const AuthInitial());

  final AuthRepository _repository;

  Future<void> checkAuth() async {
    emit(const AuthLoading());

    try {
      if (!await _repository.isAuthenticated()) {
        emit(const Unauthenticated());
        return;
      }

      final user = await _repository.getCurrentUser();
      if (user != null) {
        emit(Authenticated(user));
      } else {
        emit(const Unauthenticated());
      }
    } catch (error) {
      emit(AuthError(_resolve(error, fallback: AuthErrorCode.checkAuthFailed)));
    }
  }

  Future<void> loginWithGoogle() async {
    emit(const AuthLoading());

    try {
      final user = await _repository.signInWithGoogle();
      emit(Authenticated(user));
    } catch (error) {
      final code = _resolve(error);
      if (code == AuthErrorCode.signInCanceled) {
        emit(const Unauthenticated());
        return;
      }
      emit(AuthError(code));
    }
  }

  Future<void> loginWithPassword({
    required String identifier,
    required String password,
  }) async {
    emit(const AuthLoading());

    try {
      final user = await _repository.signInWithPassword(
        identifier: identifier,
        password: password,
      );
      emit(Authenticated(user));
    } catch (error) {
      emit(AuthError(_resolve(error, fallback: AuthErrorCode.invalidCredentials)));
    }
  }

  /// Register: sends OTP only when email is not registered.
  Future<void> sendRegisterEmailOtp(String email, {bool silent = false}) async {
    if (!silent) emit(const AuthLoading());

    try {
      final normalized = email.trim().toLowerCase();
      await _repository.sendRegisterEmailOtp(normalized);
      emit(AuthEmailOtpSent(email: normalized, purpose: AuthOtpPurpose.register));
    } catch (error) {
      final normalized = email.trim().toLowerCase();
      if (_isOtpCooldown(error)) {
        emit(
          AuthEmailOtpSent(
            email: normalized,
            purpose: AuthOtpPurpose.register,
            resumedWithoutResend: true,
          ),
        );
        return;
      }
      if (silent) return;
      _emitFailure(error, fallback: AuthErrorCode.emailOtpSendFailed);
    }
  }

  /// Forgot password: sends OTP only when email is registered.
  Future<void> sendResetPasswordEmailOtp(String email, {bool silent = false}) async {
    if (!silent) emit(const AuthLoading());

    try {
      final normalized = email.trim().toLowerCase();
      await _repository.sendResetPasswordEmailOtp(normalized);
      emit(AuthEmailOtpSent(email: normalized, purpose: AuthOtpPurpose.resetPassword));
    } catch (error) {
      final normalized = email.trim().toLowerCase();
      if (_isOtpCooldown(error)) {
        emit(
          AuthEmailOtpSent(
            email: normalized,
            purpose: AuthOtpPurpose.resetPassword,
            resumedWithoutResend: true,
          ),
        );
        return;
      }
      if (silent) return;
      _emitFailure(error, fallback: AuthErrorCode.emailOtpSendFailed);
    }
  }

  /// Resend from OTP step: returns error code without leaving OTP UI.
  Future<AuthErrorCode?> resendRegisterEmailOtp(String email) async {
    try {
      final normalized = email.trim().toLowerCase();
      await _repository.sendRegisterEmailOtp(normalized);
      emit(AuthEmailOtpSent(email: normalized, purpose: AuthOtpPurpose.register));
      return null;
    } catch (error) {
      return _resolveFailure(error, fallback: AuthErrorCode.emailOtpSendFailed).code;
    }
  }

  Future<AuthErrorCode?> resendResetPasswordEmailOtp(String email) async {
    try {
      final normalized = email.trim().toLowerCase();
      await _repository.sendResetPasswordEmailOtp(normalized);
      emit(AuthEmailOtpSent(email: normalized, purpose: AuthOtpPurpose.resetPassword));
      return null;
    } catch (error) {
      return _resolveFailure(error, fallback: AuthErrorCode.emailOtpSendFailed).code;
    }
  }

  Future<int> emailOtpRetryAfterSeconds(String email) =>
      _repository.emailOtpRetryAfterSeconds(email);

  bool _isOtpCooldown(Object error) {
    if (error is AuthFailure) {
      return error.code == AuthErrorCode.emailOtpRateLimited;
    }
    return _resolve(error) == AuthErrorCode.emailOtpRateLimited;
  }

  Future<void> verifyEmailOtp({
    required String email,
    required String token,
    required AuthOtpPurpose purpose,
  }) async {
    emit(const AuthLoading());

    try {
      final normalized = email.trim().toLowerCase();
      await _repository.verifyEmailOtp(email: normalized, token: token);
      emit(AuthPasswordSetupRequired(email: normalized, purpose: purpose));
    } catch (error) {
      emit(AuthError(_resolve(error, fallback: AuthErrorCode.emailOtpVerifyFailed)));
    }
  }

  Future<void> completePasswordSetup(String password) async {
    emit(const AuthLoading());

    try {
      final user = await _repository.setPassword(password);
      emit(Authenticated(user));
    } catch (error) {
      emit(AuthError(_resolve(error, fallback: AuthErrorCode.passwordUpdateFailed)));
    }
  }

  /// Установить / сменить пароль в уже открытой сессии (Настройки).
  /// Не трогает [AuthState], чтобы не сбрасывать стек навигации.
  Future<AuthErrorCode?> updateSessionPassword(String password) async {
    try {
      await _repository.setPassword(password);
      return null;
    } catch (error) {
      return _resolve(error, fallback: AuthErrorCode.passwordUpdateFailed);
    }
  }

  /// Настройки: есть ли пароль у текущего пользователя (RPC).
  Future<bool> currentUserHasPassword() => _repository.currentUserHasPassword();

  String? currentUserEmail() => _repository.currentUserEmail();

  /// Сброс пароля из настроек: OTP без смены [AuthState] (остаёмся Authenticated).
  /// `null` — письмо ушло или кулдаун: можно показать шаг ввода кода.
  /// При кулдауне повторно не шлём — клиент просто открывает OTP.
  Future<AuthErrorCode?> sendSessionResetPasswordOtp() async {
    final email = _repository.currentUserEmail();
    if (email == null) return AuthErrorCode.emailInvalid;
    try {
      await _repository.sendResetPasswordEmailOtp(email);
      return null;
    } catch (error) {
      if (_isOtpCooldown(error)) return null;
      return _resolve(error, fallback: AuthErrorCode.emailOtpSendFailed);
    }
  }

  Future<AuthErrorCode?> verifySessionResetPasswordOtp(String token) async {
    final email = _repository.currentUserEmail();
    if (email == null) return AuthErrorCode.emailInvalid;
    try {
      await _repository.verifyEmailOtp(email: email, token: token);
      return null;
    } catch (error) {
      return _resolve(error, fallback: AuthErrorCode.emailOtpVerifyFailed);
    }
  }

  void backToUnauthenticated() {
    emit(const Unauthenticated());
  }

  Future<void> logout() async {
    emit(const AuthLoading());

    try {
      await _repository.signOut();
      emit(const Unauthenticated());
    } catch (error) {
      _emitFailure(error, fallback: AuthErrorCode.signOutFailed);
    }
  }

  void _emitFailure(Object error, {AuthErrorCode? fallback}) {
    emit(_resolveFailure(error, fallback: fallback));
  }

  AuthError _resolveFailure(Object error, {AuthErrorCode? fallback}) {
    final code = _resolve(error, fallback: fallback);
    final retry = error is AuthFailure ? error.retryAfterSeconds : null;
    return AuthError(code, retryAfterSeconds: retry);
  }

  AuthErrorCode _resolve(Object error, {AuthErrorCode? fallback}) {
    final code = AuthErrorMapper.resolve(error);
    if (code == AuthErrorCode.unknown && fallback != null) {
      return fallback;
    }
    return code;
  }
}
