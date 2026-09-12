export const AUTH_MESSAGES = {
  invalidCredentials: "Неверный ник/email или пароль",
  identifierInvalid: "Укажите ник или email",
  emailInvalid: "Укажите корректный email",
  passwordTooShort: "Пароль не короче 8 символов",
  emailAlreadyRegistered: "Этот email уже зарегистрирован — войдите",
  emailNotRegistered: "Email не найден — сначала создайте аккаунт",
  otpInvalid: "Неверный или устаревший код",
  otpRateLimited: (seconds: number) => {
    const sec = Math.max(0, Math.ceil(seconds));
    if (sec <= 0) return "Слишком много писем. Подождите и попробуйте снова";
    const m = Math.floor(sec / 60);
    const s = sec % 60;
    return `Подождите ${m}:${String(s).padStart(2, "0")} перед повторной отправкой кода`;
  },
  generic: "Не удалось выполнить действие. Попробуйте ещё раз",
  googleFailed: "Не удалось войти через Google",
} as const;

export const MIN_PASSWORD_LENGTH = 8;
