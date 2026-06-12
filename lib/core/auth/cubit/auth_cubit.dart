import 'package:clover/core/auth/cubit/auth_state.dart';
import 'package:clover/core/auth/errors/auth_error_code.dart';
import 'package:clover/core/auth/errors/auth_error_mapper.dart';
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

  Future<void> logout() async {
    emit(const AuthLoading());

    try {
      await _repository.signOut();
      emit(const Unauthenticated());
    } catch (error) {
      emit(AuthError(_resolve(error, fallback: AuthErrorCode.signOutFailed)));
    }
  }

  AuthErrorCode _resolve(Object error, {AuthErrorCode? fallback}) {
    final code = AuthErrorMapper.resolve(error);
    if (code == AuthErrorCode.unknown && fallback != null) {
      return fallback;
    }
    return code;
  }
}
