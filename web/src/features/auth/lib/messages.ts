export const AUTH_MESSAGES = {
  invalidCredentials: "Неверный ник/email или пароль",
  identifierInvalid: "Укажите ник или email",
  emailInvalid: "Укажите корректный email",
  passwordTooShort: "Пароль не короче 8 символов",
  emailAlreadyRegistered: "Этот email уже зарегистрирован — войдите",
  emailNotRegistered: "Email не найден — сначала создайте аккаунт",
  otpInvalid: "Неверный или устаревший код",
  generic: "Не удалось выполнить действие. Попробуйте ещё раз",
  googleFailed: "Не удалось войти через Google",
} as const;

export const MIN_PASSWORD_LENGTH = 8;
