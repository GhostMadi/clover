# App Store — тексты листинга (RU)

**Статус:** готово к вставке в App Store Connect  
**Связано с:** [website.md](website.md) · [mobile-deploy.md](mobile-deploy.md)

> Тон: приглашающий, обобщённый (B2B + B2C), без длинного списка экранов.  
> Перед продом сверить юр. имя в copyright и URL на сайте.

Лимиты Apple: подзаголовок **30**, рекламный текст **170**, описание **4000**, ключевые слова **100**.

---

## URL для App Store Connect

| Поле | URL |
|------|-----|
| Поддержка | https://clover.com.kz/support |
| Политика конфиденциальности | https://clover.com.kz/privacy |
| Параметры конфиденциальности пользователей | https://clover.com.kz/privacy-choices |
| Сайт | https://clover.com.kz |

---

## Подзаголовок (30)

```
Помощник для бизнеса
```

---

## Рекламный текст (170)

```
Clover — помощник со всеми сервисами для бизнеса в одном месте. Для вас и ваших клиентов. Просто и бесплатно.
```

---

## Описание

```
Clover — помощник для бизнеса.

Один вход — и рядом все нужные сервисы: чтобы развивать дело, работать с клиентами и командой, без россыпи приложений и чатов.

Подходит тем, кто ведёт бизнес, и тем, кто к нему обращается.
Всё собрано в одном спокойном приложении.

Сейчас — бесплатно.

Сайт: https://clover.com.kz
Поддержка: https://clover.com.kz/support
```

> Обращения — только через форму на `/support` (не email `welcome@…`: это отправитель OTP).

---

## Ключевые слова (≤100)

```
бизнес,помощник,запись,клиенты,услуги,маркетинг,команда,салон,расписание,приложение
```

---

## Авторские права

```
2026 Clover
```

(если есть ТОО / ИП — подставь официальное имя)

---

## Privacy Nutrition Labels

Ориентир: Contact Info, User Content, Identifiers, Location (по разрешению), Diagnostics (**Sentry**: crashes + performance) — **не** продаём данные, **не** трекинг ради чужой рекламы, если SDK рекламы нет. Подробнее: `/privacy`, `/privacy-choices`, [app-store-privacy-labels.md](app-store-privacy-labels.md).

---

## Чеклист перед Submit

### Листинг и метаданные

- [ ] URL support / privacy / privacy-choices / terms / delete-account открываются на проде
- [ ] Copyright = реальное имя правообладателя
- [ ] Скриншоты = реальный UI билда (не splash / login только)
- [ ] Age rating честно под UGC (обычно **12+**, не 4+)
- [ ] Privacy Labels по [app-store-privacy-labels.md](app-store-privacy-labels.md) — в т.ч. **Crash + Performance (Sentry)**

### App Review Information

- [ ] **Demo account** в ASC: логин + пароль (или OTP-инструкция), аккаунт с контентом в ленте и вторым пользователем для Report/Block
- [ ] Backend live на время Review
- [ ] Notes — вставить блок из [ugc-safety.md](ugc-safety.md) § «Текст для ASC»
- [ ] К Notes приложить **screen recording** (физическое устройство): Terms checkbox → Report → Block → пост пропадает из Event
- [ ] В Notes кратко: Sign in with Apple; деактивация in-app vs hard delete на https://clover.com.kz/delete-account; геолокация только While In Use (карта / punch)

### Демо-аккаунт (заполнить перед Submit)

| Поле ASC | Значение |
|----------|----------|
| Username / email | _(создать и вписать)_ |
| Password | _(вписать)_ |
| Notes hint | Second account for Report/Block: _(ник/email)_ · sample post already visible in Event feed |

> Аккаунт должен быть активен, с галочкой Terms уже пройденной или с возможностью показать чекбокс на свежем логине. Для записи UGC удобнее второй тестовый профиль с постом.
