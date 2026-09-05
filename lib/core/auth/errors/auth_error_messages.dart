import 'package:clover/core/auth/errors/auth_error_code.dart';

/// User-facing auth error texts resolved by [AuthErrorCode].
abstract final class AuthErrorMessages {
  static String messageFor(AuthErrorCode code, {int? retryAfterSeconds}) {
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
      AuthErrorCode.emailInvalid => 'Введите корректный email.',
      AuthErrorCode.emailOtpSendFailed =>
        'Не удалось отправить код на email. Попробуйте позже.',
      AuthErrorCode.emailOtpVerifyFailed =>
        'Неверный или просроченный код. Запросите новый.',
      AuthErrorCode.emailOtpRateLimited => () {
        final sec = retryAfterSeconds ?? 0;
        if (sec <= 0) {
          return 'Слишком много писем. Подождите и попробуйте снова.';
        }
        final m = sec ~/ 60;
        final s = sec % 60;
        return 'Подождите $m:${s.toString().padLeft(2, '0')} перед повторной отправкой.';
      }(),
      AuthErrorCode.emailAlreadyRegistered =>
        'Этот email уже зарегистрирован. Войдите или сбросьте пароль.',
      AuthErrorCode.emailNotRegistered =>
        'Аккаунт с этим email не найден. Создайте аккаунт.',
      AuthErrorCode.invalidCredentials => 'Неверный логин или пароль.',
      AuthErrorCode.passwordInvalid =>
        'Пароль слишком короткий. Минимум 8 символов.',
      AuthErrorCode.passwordMismatch => 'Пароли не совпадают.',
      AuthErrorCode.passwordUpdateFailed =>
        'Не удалось сохранить пароль. Попробуйте ещё раз.',
      AuthErrorCode.identifierInvalid => 'Введите ник или email.',
    };
  }
}
