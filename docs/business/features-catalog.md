# Каталог фич Clover

Карта продукта: что умеет Clover, описан ли бизнес-процесс, сделано ли технически и где лежит код.

---

## Статусы

- 🟢 **Ок** — бизнес описан (или так и задумано) **и** техника в продукте работает  
- 🟡 **Зазор** — в приложении уже есть, но бизнес-дока нет / сценарий дырявый / описано только вскользь  
- 🔴 **Дыра** — только бэк, не сделано, или важный кусок отсутствует  

У каждой фичи: статус → коротко что это → бизнес → техника → путь.

---

## Вход и старт

### 🟡 Аутентификация (целевая модель)
**План:** логин ник/email + пароль; регистрация OTP (почта/SMS) → пароль или Google/Apple; установка/сброс пароля.  
**Сейчас в UI:** логин ник/email+пароль, регистрация email OTP (только новым), сброс пароля, Google.  
Бизнес: [authentication.md](authentication.md)  
Техника: `lib/feature/auth/`, `lib/core/auth/` · миграция `20260831100000_auth_login_helpers.sql`

### 🟡 Email OTP / транзакционная почта (Resend)
Доставка OTP с **welcome@clover.com.kz** (домен **Verified**). Для регистрации и сброса пароля, не как основной логин.  
Бизнес: [email-authentication.md](email-authentication.md)  
Техника: [../supabase/SPEC_EMAIL_AUTH.md](../supabase/SPEC_EMAIL_AUTH.md)

### 🔴 Phone / WhatsApp OTP
Регистрация / сброс по номеру (OTP → пароль) — в целевом плане auth.  
Бизнес: [authentication.md](authentication.md) § Регистрация  
Техника: пока бэк — `supabase/functions/send_sms_hook/`. В UI нет

### 🔴 WhatsApp webhook
Входящие события Meta (не OTP-логин).  
Бизнес: не описан  
Техника: только бэк — `supabase/functions/whatsapp_webhook/`

### 🟢 Онбординг
Шесть слайдов после входа; повтор из «О приложении».  
Бизнес: [onboarding.md](onboarding.md)  
Техника: `lib/feature/onboarding/`

### 🟢 Сессия и выход
Остаёшься в аккаунте между запусками; выход из настроек.  
Бизнес: [authentication.md](authentication.md) · [settings.md](settings.md)  
Техника: auth + `lib/feature/_settings_/settings_account/`

---

## Навигация и главный экран

### 🟢 Нижний бар
Вкладки Event/Map, Chat, Profile. Навбар **всегда по центру**. На главной: фильтр слева, уведомления справа.  
Бизнес: [navigation-bars.md](navigation-bars.md)  
Техника: `lib/feature/dashboard_page/`, `lib/core/shared/app_nav_bar/`

### 🟢 Лента ↔ карта
Двойной тап по первой вкладке.  
Бизнес: в navigation-bars  
Техника: `dashboard_page/` (Home mode)

### 🟢 Фильтры ленты и карты
Страна, город, «Все/Ивенты», даты, эмодзи, теги; отдельно — фильтры витрины профиля.  
Бизнес: [filters.md](filters.md)  
Техника: `lib/feature/_feed_/events_page/`, `lib/feature/_feed_/map_page/`, `lib/feature/_settings_/settings_filter/`

### 🟢 Уведомления
Центр уведомлений с Home: соц (лайки, комменты, подписки) + запись (instant booking). Бейдж на колокольчике. Push — позже.  
Бизнес: [notifications.md](notifications.md) · запись — [booking.md](booking.md)  
Техника: `lib/feature/_feed_/notification_page/` · [SPEC_IN_APP_NOTIFICATIONS.md](../supabase/SPEC_IN_APP_NOTIFICATIONS.md)

---

## Профиль

### 🟢 Свой профиль
Витрина: шапка, счётчики, публикации, настройки.  
Бизнес: [profile.md](profile.md)  
Техника: `lib/feature/_profile_/profile_page/`

### 🟢 Чужой профиль
Подписка, чат, запись (если хозяин принимает).  
Бизнес: в profile.md  
Техника: guest profile в `_profile_/profile_page/`

### 🟢 Редактирование профиля
Имя, ник, био, фото, место, теги.  
Бизнес: profile + [profile-data.md](profile-data.md)  
Техника: `lib/feature/_profile_/edit_profile/`

### 🟢 Подписчики и подписки
Списки из счётчиков шапки; новая подписка → in-app уведомление.  
Бизнес: [profile.md](profile.md) · [notifications.md](notifications.md)  
Техника: `_profile_/followers_and_followings/`, `_catalog_/social_graph/`

### 🟢 Теги (единый справочник)
Профиль, маркеры, фильтры — один список: `salon`, `business`, `booking`, …  
Бизнес: profile / profile-data  
Техника: `_catalog_/marker_tags/` + `profile_tag_links`, edit через `MultiMarkerTags`

### 🟢 «Бизнес-профиль» (как отдельный тип)
Отдельного экрана нет — **так и задумано**: один профиль + теги, запись, бонусы.  
Бизнес: не нужна отдельная фича, пока модель такая  
Техника: отдельного модуля нет

### 🟢 Меню «⋯» у Profile
Мои бронирования, мои бонусы.  
Бизнес: profile / navigation  
Техника: sheet у дашборда профиля

---

## Публикации, ивенты, карта

### 🟢 Публикации и ивенты
Обычный пост или ивент (пост + маркер + период ≤ 24 ч). Лента по умолчанию «Все»; карта — только ивенты.  
Бизнес: [publications.md](publications.md)  
Техника: `_post_/post/`, `_post_/post_create/`, `_feed_/events_page/`, `_feed_/map_page/`

### 🟢 Создание публикации / ивента
С профиля через «+».  
Бизнес: в publications  
Техника: `post_create` → `PostCreateRepository.publish()` (REST + Storage; Edge `create_post` — legacy)

### 🟢 Реакции
Like / dislike на постах; уведомления автору.  
Бизнес: [reactions.md](reactions.md) · [notifications.md](notifications.md)  
Техника: UI поста + `set_post_reaction`

### 🟢 Комментарии
Шторка к посту, ответы, лайки комментариев.  
Бизнес: [comments.md](comments.md) · [notifications.md](notifications.md)  
Техника: `_post_/post_comment/`

### 🟢 Шаринг поста в чат
Только внутри Clover — подписки, превью поста в DM.  
Бизнес: [chats.md](chats.md) (раздел «Поделиться постом»)  
Техника: `_post_/post_share/` + `chat_message_post_refs`

### 🟢 Сохранённые посты
Закладки из ленты / поста; список в настройках.  
Бизнес: [saved-posts.md](saved-posts.md)  
Техника: `_settings_/settings_saved_post/`

### 🟢 Архивы
Публикации / ивенты / кластеры автора.  
Бизнес: [archives.md](archives.md)  
Техника: `_archive_/` (посты, ивенты), `_cluster_/cluster_archive/`

---

## Кластеры

### 🟢 Кластеры
Коллекции на витрине: создать, фильтр сетки, привязка поста, архив.  
Бизнес: [clusters.md](clusters.md)  
Техника: `lib/feature/_cluster_/`, архив в `_cluster_/cluster_archive/`

---

## Чаты и соцсеть

### 🟢 Список чатов и переписка
Вкладка Chat, DM и группы, текст, фото/документы, реакции, поиск по сообщениям (FTS), превью постов, прочитано, открытие с профиля.  
Бизнес: [chats.md](chats.md)  
Техника: `_chat_/message_page/`, `_chat_/chat_page/`, `_chat_/chat/`

### 🟢 Подписки (follow)
См. [Подписчики и подписки](#-подписчики-и-подписки) выше.

### 🟡 Блокировки
Бэк (`profile_blocks`); UI блокировки **нет**.  
Бизнес: [blocks.md](blocks.md)  
Техника: social graph на бэке, follow в Flutter

---

## Запись и бонусы

### 🟢 Онлайн-запись
Хозяин (тег `booking`) настраивает услуги и расписание; клиент записывается с профиля или с поста с услугой; «Мои бронирования» через ⋯.  
Бизнес: [booking.md](booking.md)  
Техника: `lib/feature/_booking_/`, [SPEC_BOOKING_SYSTEM.md](../supabase/SPEC_BOOKING_SYSTEM.md)

### 🟢 Бонусы
Начисление и списание настраиваются на услуге; «Мои бонусы» у клиента.  
Бизнес: [bonuses.md](bonuses.md)  
Техника: `lib/feature/_bonus_/`, `supabase/migrations/_bonus/FLOW.md`

### 🟡 Посещаемость
Admin + worker: полный бизнес-процесс по собранным mock-экранам; chat-карточки invite/правил; «Сегодня на смене»; **0 запросов** для неучастников.  
Бэк ядра 🟡: workplace / membership / punch / absences + bootstrap RPC; OT / payroll / live chat-карточки — следующие срезы.  
Бизнес: [attendance.md](attendance.md)  
Техника: `lib/feature/_attendance_/`, [SPEC_ATTENDANCE_SYSTEM.md](../supabase/SPEC_ATTENDANCE_SYSTEM.md), `supabase/migrations/_attendance/`

---

## Настройки

### 🟢 Настройки приложения
Хаб, аккаунт, тема, «О приложении», ресурсы, архивы, сохранённые.  
Бизнес: [settings.md](settings.md)  
Техника: `_settings_/settings/`, `_settings_/settings_account/`, `_settings_/settings_about/`, … + `lib/core/theme/`

### 🔴 Сон / сброс аккаунта
Состояния вроде hibernate на бэке.  
Бизнес: не описан  
Техника: в основном бэк, понятного полного UX мало

---

## Справочники и данные

### 🟢 Правило локализации
Бэк = английские ключи; фронт = enum + перевод.  
Бизнес: [localization-dictionaries.md](localization-dictionaries.md)  
Техника: enums стран, городов, тегов

### 🟢 Справочники на клиенте
Enum + catalog: страны, города, теги без sync с бэка.  
Бизнес: [catalog-sync.md](catalog-sync.md)  
Техника: `feature/_catalog_/`, `MarkerTagsCatalog`, `CountriesCatalog`, `CitiesCatalog`

### 🟢 Локации пользователя
Сохранённые места для постов и ивентов.  
Бизнес: [locations.md](locations.md)  
Техника: `lib/feature/_catalog_/location/`

---

## Сводка одним взглядом

**🟢 Ок**  
Google-вход · **сессия/выход** · онбординг · нижний бар · лента↔карта · **фильтры** · профиль (свой/чужой) · edit · теги · **подписчики** · меню ⋯ · публикации/ивенты · создание · **реакции** · **комментарии** · **сохранённые** · **архивы** · **кластеры** · **чаты** · **уведомления in-app** · **настройки** · **локации** · локализация ключей · enum-справочники · «бизнес-профиль» не отдельный тип · **онлайн-запись** · **бонусы**

**🟡 Зазор — техника есть, дока мало или дырка в UX**  
**блокировки** (нет UI)

**🔴 Дыра**  
Phone / WhatsApp OTP в UI · WhatsApp webhook как продуктовый процесс · сон/сброс аккаунта для человека

---

## Как обновлять

Новая фича — абзац со статусом 🟢 / 🟡 / 🔴.  
Появился бизнес-док или довели UI — смени цвет.
