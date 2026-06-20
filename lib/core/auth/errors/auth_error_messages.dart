import 'package:clover/core/auth/errors/auth_error_code.dart';

/// User-facing auth error texts resolved by [AuthErrorCode].
abstract final class AuthErrorMessages {
  static String messageFor(AuthErrorCode code) {
    return switch (code) {
      AuthErrorCode.unknown => 'Что-то пошло не так. Попробуйте ещё раз.',
      AuthErrorCode.checkAuthFailed =>
        'Не удалось восстановить сессию. Войдите снова.',
      AuthErrorCode.signInCanceled => 'Вход отменён.',
      AuthErrorCode.googleIdTokenMissing =>
        'Не удалось войти через Google. Попробуйте ещё раз.',
      AuthErrorCode.googleSignInFailed =>
        'Не удалось войти через Google. Попробуйте ещё раз.',
      AuthErrorCode.googleClientMisconfigured =>
        'Google Sign-In не настроен: проверьте Web Client ID в Google Cloud и Supabase.',
      AuthErrorCode.supabaseSignInFailed =>
        'Не удалось выполнить вход. Попробуйте позже.',
      AuthErrorCode.supabaseUserMissing =>
        'Не удалось загрузить профиль после входа.',
      AuthErrorCode.signOutFailed =>
        'Не удалось выйти из аккаунта. Попробуйте ещё раз.',
      AuthErrorCode.networkError =>
        'Ошибка сети. Проверьте подключение и попробуйте снова.',
    };
  }
}
