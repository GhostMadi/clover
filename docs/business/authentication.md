# Аутентификация Clover

**Статус:**  
- **Сейчас в приложении:** Google + Apple (native iOS) + email OTP / ник+пароль ([email-authentication.md](email-authentication.md))  
- **Целевая модель:** логин ник/email + пароль; регистрация через OTP (почта / SMS) или Google / Apple  

**Для кого:** продукт / поддержка / онбординг команды  
**Не про:** код, секреты, API-ключи  
**Техника email OTP (Hook + Resend REST):** [../supabase/SPEC_EMAIL_AUTH.md](../supabase/SPEC_EMAIL_AUTH.md)

---

## Цель

Пользователь безопасно входит в Clover и получает один аккаунт.  
Повседневный вход — **ник или почта + пароль**.  
Первичная регистрация и восстановление — через **подтверждение (OTP)** или **соцвход (Google / Apple)**.

---

## Целевая модель (план)

### Экран логина

| Элемент | Смысл |
|---------|--------|
| Поле 1 | **Ник или email** (одно поле) |
| Поле 2 | **Пароль** |
| CTA | **Войти** |
| Ссылки | «Забыли пароль?» · «Создать аккаунт» |
| Соцкнопки | Google · Apple (iOS) |

OTP **не** является основным способом ежедневного входа. Код нужен при **регистрации**, **сбросе пароля** и (при необходимости) подтверждении контакта.

```
Экран входа
├── ник / email
├── пароль
├── Войти
├── Забыли пароль?
├── Создать аккаунт
└── Google · Apple (iOS)
```

---

### Регистрация

Пользователь выбирает канал создания аккаунта:

| Способ | Шаги (продукт) |
|--------|----------------|
| **Email** | email → OTP на welcome@clover.com.kz → ввод кода → **установка пароля** → профиль / онбординг |
| **SMS / телефон** | номер → OTP (SMS/WhatsApp) → ввод кода → **установка пароля** → профиль / онбординг |
| **Google** | Continue with Google → аккаунт сразу · пароля может не быть |
| **Apple** | Continue with Apple (iOS) → как Google |

Правила:

1. После OTP-регистрации пароль **обязателен** (полноценный аккаунт с паролем).
2. После Google / Apple пароль **не обязателен сразу** — можно пользоваться приложением.
3. Ник (username) — уникальный идентификатор профиля; для логина «по нику» Clover должен уметь найти аккаунт по нику и проверить пароль.
4. **Регистрация:** OTP **не** отправляется, если email уже **завершённый** аккаунт (есть пароль или Google/Apple). Незавершённая регистрация (код уже слали, пароль ещё не задали) — можно отправить код снова (с hourly-лимитом).
5. **Сброс пароля:** OTP отправляется **только** если email уже есть в Auth.
6. **Лимит отправки:** не больше **3** OTP-писем на один email за скользящий час (register и reset — один счётчик). Гейт — Auth Send Email Hook; клиентский peek — только UX.

---

### Нет пароля (Google / Apple / старый аккаунт)

| Ситуация | Что можно |
|----------|-----------|
| Пароля нет (бэк: `encrypted_password` пустой) | **Настройки → Аккаунт → «Установить пароль»** — задать сразу, пока сессия жива. Пока пароля нет — статус каждый раз с бэка |
| Пароль уже есть | **«Сбросить пароль»** — OTP → новый. После первого `true` с бэка (или после установки) флаг кэшируется локально — повторный RPC не нужен |

Смысл: соцвход не блокирует потом обычный вход по нику/email + пароль на другом устройстве. Правда «есть пароль или нет» — только с бэка, не по identity в клиенте.

---

### Забыли пароль

1. На логине → **«Забыли пароль?»**.
2. Вводит **email** (или телефон — если аккаунт привязан к номеру).
3. Получает OTP / ссылку восстановления.
4. Подтверждает код → **задаёт новый пароль**.
5. Снова может войти с ник/email + пароль.

Если аккаунт только Google и email не подтверждён / не привязан — отдельное сообщение: войти через Google и установить пароль в настройках.

---

## Схемы

### Логин (ежедневно)

```
ник или email + пароль
    → проверка
    → сессия
    → онбординг (если ещё не пройден) / дашборд
```

### Регистрация по почте

```
email → OTP (Resend) → код → задать пароль → (ник при онбординге/профиле) → приложение
```

### Регистрация Google

```
Google → аккаунт Clover
    → можно сразу в приложение
    → опционально позже: Настройки → Установить пароль
```

### Сброс пароля

```
Забыли пароль? → email/телефон → OTP → новый пароль → логин
```

---

## Что есть сейчас (факт)

| Тема | Сейчас |
|------|--------|
| Логин ник/email + пароль | ✅ mobile + web |
| Регистрация + установка пароля | ✅ email OTP → пароль |
| Google | ✅ |
| Email OTP + hourly gate (3/email) | ✅ Send Email Hook + RPC |
| SMS / WhatsApp OTP | бэк частично; UI нет |
| Apple | ✅ native iOS (`signInWithIdToken` + nonce) |
| Установить пароль после Google / Apple | ✅ настройки аккаунта |
| Сброс пароля | ✅ forgot OTP |

Подробно про почтовый шлюз: [email-authentication.md](email-authentication.md).

Целевая модель выше в основном live; SMS — ещё план.

---

## Google native (iOS / Android)

Мобилка: **Google Sign-In → idToken → Supabase** (`signInWithIdToken`), без браузера.  
Сайт: redirect OAuth через Web client — [website.md](website.md).

Все OAuth clients — **один** Google Cloud project (тот же, что «Clover Web Client» / iOS client, prefix `1041927738445`).

| Клиент | Назначение |
|--------|------------|
| **Web** | Supabase Client ID + Secret; в приложении — `serverClientId` (audience idToken) |
| **iOS** | Bundle `clover.mobile.com` → Info.plist `GIDClientID` |
| **Android** | Package `clover.mobile.com` + SHA-1 fingerprint |

### Supabase → Auth → Providers → Google

1. **Client ID / Secret** = только **Web** (не Android).  
2. Если есть **Authorized Client IDs** — iOS и Android Client ID через запятую.  
3. **Skip nonce checks** — включено.

Если в Client ID лежит только Android — веб и native idToken с Web audience сломаются: верни Web + Secret.

### Android (чеклист)

1. Google Cloud → APIs & Services → Credentials → Create **OAuth client ID** → **Android**  
   - Package: `clover.mobile.com` (как iOS / Play)  
   - SHA-1 debug: `CA:30:25:07:AC:A1:1F:B6:9D:2A:F0:B2:17:32:89:0F:3B:2F:95:99`  
   - SHA-1 upload (Play): `59:5B:6E:5B:00:43:5A:57:C8:3C:1F:3D:A4:05:7C:57:F7:E8:CD:F2`  
   - После Play App Signing — ещё SHA-1 **App signing** из Console.  
2. Firebase project `clover-52112` → Project settings → Android app → **Add fingerprint** (тот же SHA-1) → скачать новый `google-services.json` в `android/app/` (в `oauth_client` должны появиться записи; пустой массив = Sign-In часто падает с developer error).  
3. Пересобрать приложение после смены `google-services.json` / SHA.

Код: `GoogleAuthConfig.webClientId` + `iosClientId`; init в `configureDependencies`.

---

## Apple native (iOS)

Мобилка: **Sign in with Apple → idToken + nonce → Supabase** (`signInWithIdToken`), без браузера.  
Кнопка на login / register — только iOS (`AuthAppleSignInButton`).

### Apple Developer

1. App ID `clover.mobile.com` — capability **Sign in with Apple**.  
2. Services ID `app.clover.mobile.auth` — для web/OAuth secret (если нужен сайт).  
3. Key `.p8` → Secret Key (JWT) в Supabase (срок до 6 мес.).

### Supabase → Auth → Providers → Apple

1. Включить Apple.  
2. **Client IDs:** bundle `clover.mobile.com` (+ Services ID `app.clover.mobile.auth` первым, если будет web OAuth).  
3. Secret Key / Team ID / Key ID — для OAuth secret (web); native idToken проверяет audience = App ID.

### iOS

- Entitlements: `com.apple.developer.applesignin` = `Default` (Debug / Profile / Release).  
- Код: `AuthRepository.signInWithApple` + `AuthCubit.loginWithApple`.

---

## Сессии (v1)

**Решение:** параллельные сессии **разрешены**. Первый успешный вход на аккаунт = **главный** (`primary`); все следующие устройства/клиенты = **гости** (`guest`).

```
Первый вход (телефон или веб)
    → primary (главный), без алерта «новый вход»

Вход с другого устройства
    → guest; сессия жива; главному — уведомление

Logout на одном клиенте
    → только эта сессия; wipe локального кэша этого клиента
```

### Уведомление о гостевом входе

После **успешного нового входа** клиент вызывает RPC `report_account_login` (с `session_id` из JWT, если есть):

1. В журнал `account_login_events` — client / platform / device_label / role / status / session_id.  
2. Если вход **guest** и fingerprint не «доверенный» — в ленту kind **`account_login`** главному.  
3. Опционально — push (`push_outbox`, EN keys → localize в drain).

В уведомлении действия (EN keys → подписи на клиенте):

| Действие | Смысл |
|----------|--------|
| `confirm` | «Это я» — пометить гостя доверенным (`confirmed`) |
| `revoke` | «Прервать» — отозвать эту гостевую Auth-сессию |
| `change_password` | «Сменить пароль» — открыть поток пароля в настройках |

Анти-спам: повтор с тем же fingerprint за **12 ч** без notify; confirmed fingerprint **30 дней** без notify; повтор с fingerprint **primary** без notify.

Список недавних входов (role / status) — в настройках аккаунта.

Техника: [SPEC_ACCOUNT_LOGIN_EVENTS.md](../supabase/SPEC_ACCOUNT_LOGIN_EVENTS.md).

---

## Очерёдность внедрения (план)

| # | Этап | Зачем |
|---|------|--------|
| 1 | Убрать/спрятать тестовый OTP-блок с login | Не путать с целевым UX |
| 2 | Регистрация по **email**: OTP → установка пароля | Уже есть Resend Verified |
| 3 | Экран **логина**: ник/email + пароль | Основной ежедневный вход |
| 4 | **Установить / сбросить пароль** в настройках по флагу с бэка | Закрыть кейс «Google без пароля» и «забыл, уже в приложении» |
| 5 | **Забыли пароль** (email OTP → новый пароль) | Восстановление |
| 6 | Регистрация / сброс через **SMS** | Когда телефонный канал готов |
| 7 | **Apple** Sign In | ✅ native iOS |
| 8 | Google / Apple на login + register | ✅ |

---

## Открытые решения (зафиксировать до кода)

| Вопрос | Варианты / заметка |
|--------|-------------------|
| Ник при регистрации | Сразу на шаге после OTP или в онбординге / edit profile? |
| Логин только ником | Нужен серверный lookup: username → auth identity (email/id) |
| Один аккаунт: Google + тот же email | Связка identities; конфликт «email уже занят» |
| Минимальная длина / правила пароля | Например 8+ символов |
| SMS-провайдер | WhatsApp hook vs классический SMS — отдельно |
| Тестовый OTP на login | Удалить после этапа 2 |
| Mobile single-session vs web multi | ❌ Снято: multi-session, primary + guest + login alerts (см. § Сессии) |

---

## Ошибки (целевой UX)

| Ситуация | Сообщение пользователю (смысл) |
|----------|--------------------------------|
| Неверный ник/email или пароль | «Неверный логин или пароль» (без утечки, что именно неверно) |
| Нет пароля у аккаунта | «Войдите через Google или установите пароль в настройках» |
| Email уже зарегистрирован | Предложить войти / сбросить пароль |
| OTP неверный / просрочен | Запросить код снова |
| Лимит **3 OTP / час** на email | «Подождите m:ss» / повторить позже (серверный гейт Hook) |
| Сбой доставки письма | Повторить позже |
---

## Связанные процессы

- [email-authentication.md](email-authentication.md) — доставка OTP-писем (инфра)
- [onboarding.md](onboarding.md) — после первого входа
- [settings.md](settings.md) — аккаунт, выход; сюда же «Установить пароль»
- [profile-data.md](profile-data.md) — username / email в профиле
- [attendance.md](attendance.md) — sync / outbox; опирается на правило сессий mobile vs web

---

## Коротко

```
Регистрация:  OTP (почта/SMS) → пароль  |  Google / Apple
Логин:        ник или email + пароль  (+ Google / Apple)
Нет пароля:   настройки → установить
Забыли:       OTP → новый пароль
Сессии:       первый вход = primary; остальные = guest + алерт главному
              (это я / прервать сессию / сменить пароль)
```
