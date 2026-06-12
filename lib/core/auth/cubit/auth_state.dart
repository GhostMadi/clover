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

final class AuthError extends AuthState {
  const AuthError(this.code);

  final AuthErrorCode code;
}
