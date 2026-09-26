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

### 🟢 Аутентификация (целевая модель email)
**План / сейчас:** логин ник/email + пароль; регистрация email OTP → пароль; сброс пароля; Google; **Apple (iOS)**. SMS — later.
Бизнес: [authentication.md](authentication.md)  
Техника: `lib/feature/auth/`, `lib/core/auth/`, `web/src/features/auth/` · [SPEC_EMAIL_AUTH.md](../supabase/SPEC_EMAIL_AUTH.md)

### 🟢 Email OTP / транзакционная почта (Resend)
Доставка OTP с **welcome@clover.com.kz** через **Send Email Hook → Edge → Resend REST**; лимит **3 / email / час**. Не основной логин.  
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
v2: выбор сюжета (лента / бизнес / оба) после входа; повтор из «О приложении».  
v3 каркас: умные service-tips (`OnboardingTipCatalog` + resolver + кэш seen) — wire UI по хабам позже.  
Бизнес: [onboarding.md](onboarding.md)  
Техника: `lib/feature/onboarding/` · правило: `.cursor/rules/clover-onboarding.mdc`

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

### 🟡 Сила тегов профиля (глобальный паттерн)
Account-тег → визуал (кнопки) + какие функции/запросы открывать на клиенте. Список тегов растёт со временем; эталон — `booking`.  
Бизнес: [tag-powers.md](tag-powers.md) · [profile-data.md](profile-data.md)  
Техника: `_catalog_/marker_tags/` + гейты в фичах (приводить к одному паттерну)

### 🟢 Теги (единый справочник)
Профиль, маркеры, фильтры — один список ключей: `salon`, `business`, `booking`, …  
Бизнес: profile / profile-data · силы: [tag-powers.md](tag-powers.md)  
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
**Live-inbox** (список + бейдж Chat без открытия треда) · **push** `chat_message` · тап/баннер → чат.
**Инфо чата:** тап по аватару/имени в шапке → участники (группа) / профиль (DM).
Бизнес: [chats.md](chats.md)
Техника: `_chat_/message_page/`, `_chat_/chat_page/`, `_chat_/chat/`, `_chat_/chat_info/`

### 🟢 Фон чата (смайлики)
Общий wallpaper на conversation: палитра → набор смайликов → все участники видят один фон.  
Бизнес: [chat-emoji-wallpaper.md](chat-emoji-wallpaper.md)  
Техника: `wallpaper_emojis` + RPC; mobile/web thread UI

### 🟢 Подписки (follow)
См. [Подписчики и подписки](#-подписчики-и-подписки) выше.

### 🟢 Блокировки
Бэк (`profile_blocks` + RPC `block_user` / `unblock_user` / `list_my_blocked_users`); UI: guest profile + Настройки → Заблокированные (mobile + web). Блок уведомляет модерацию (`content_reports`) и скрывает контент из Event/Map.
Бизнес: [blocks.md](blocks.md) · [ugc-safety.md](ugc-safety.md)  
Техника: [SPEC_SUPABASE_SOCIAL_GRAPH_AND_ACCOUNT.md](../supabase/SPEC_SUPABASE_SOCIAL_GRAPH_AND_ACCOUNT.md) · [SPEC_CONTENT_REPORTS.md](../supabase/SPEC_CONTENT_REPORTS.md) · `lib/feature/_settings_/settings_blocked/`, `lib/feature/_safety_/`

### 🟢 Жалобы на контент (UGC)
Пост / профиль → «Пожаловаться» → `report_content`; Terms до входа; модерация ≤ 24ч.
Бизнес: [ugc-safety.md](ugc-safety.md)  
Техника: [SPEC_CONTENT_REPORTS.md](../supabase/SPEC_CONTENT_REPORTS.md)
---

## Запись и бонусы

### 🟢 Онлайн-запись (+ удобства и календарь «мне дают»)
Ядро записи **уже есть и остаётся**: хозяин (`booking`), клиент, inbox, визит до «Оказана».
Дельта: удобство входов через теги / две линии на профиле; тег `bookingCalendar` + экран своих заказов (не иерархия). **ТЗ:** [booking-tz.md](booking-tz.md).
План сил: [booking-staff-plan.md](booking-staff-plan.md). Invite linked-staff через DM — mobile + web. Hub точки: **Команда** + **Чат** (`booking_open_point_chat`).
Бизнес: [booking.md](booking.md) · силы тегов: [tag-powers.md](tag-powers.md) · точки: [booking-points.md](booking-points.md)
Техника: `lib/feature/_booking_/` (в т.ч. `booking_team/`), `web/src/features/booking/`, [SPEC_BOOKING_SYSTEM.md](../supabase/SPEC_BOOKING_SYSTEM.md) · invite: [SPEC_BOOKING_STAFF_INVITE.md](../supabase/SPEC_BOOKING_STAFF_INVITE.md)

### 🟡 Бронь (билеты / места / схема)
**Моки:** мобилка смотрит · рисовалка — **Ресурсы → Схемы** (legacy venue URL до редиректа). Бэк / тег `venue` — ещё нет.  
Схема как справочник → **Ресурсы** (`space_plans`), при create **заведения** — опц. bind: [space-plan-resources.md](space-plan-resources.md).  
Бизнес: [venue-seating.md](venue-seating.md) · код: `lib/feature/_venue_/` · `web/src/features/venue/`

### 🟡 Схемы пространства в Ресурсах (mock web)
Третий тип в хабе Ресурсов: рисуем только на сайте, мобилка смотрит; create/publish в localStorage.  
Процесс COP + **ТЗ:** [space-plan-tz.md](space-plan-tz.md) · SPEC: [SPEC_SPACE_PLANS.md](../supabase/SPEC_SPACE_PLANS.md).  
Бизнес: [space-plan-resources.md](space-plan-resources.md) · web: `/app/settings/resources/space-plans`

### 🟡 Запись + схема: ценники на emoji (mock end-to-end)
Схему рисуют в Ресурсах → вешают на точку → emoji `bookable` → услуга(+мастер).  
Гость: схема **или** услуга → дата/слот → «Записаться». Бэка bind нет — очередь WP2–3 в ТЗ.  
Бизнес: [space-plan-emoji-pricing.md](space-plan-emoji-pricing.md) · ТЗ: [space-plan-tz.md](space-plan-tz.md) · web: `/app/settings/booking/p/{id}/visual` · mobile: Записаться → схема

### 🟢 Бонусы
Начисление и списание настраиваются на услуге; «Мои бонусы» у клиента.  
Бизнес: [bonuses.md](bonuses.md)  
Техника: `lib/feature/_bonus_/`, `supabase/migrations/_bonus/FLOW.md`

### 🟡 Посещаемость (+ слой тегов)
Ядро admin + worker уже есть. Дельта: теги `attendance` / `attendanceWork`, гейты create/punch, inactive без worker-тега, без prefs-ярлыка. **ТЗ:** [attendance-tz.md](attendance-tz.md).  
Бэк ядра 🟢; Flutter / веб ядро 🟢; слой тегов — по ТЗ. Групповой чат компании: `attendance_open_company_chat` (ensure + sync active).  
Бизнес: [attendance.md](attendance.md) · силы: [tag-powers.md](tag-powers.md) · веб: [website-gap-plan.md](website-gap-plan.md)  
Техника: `lib/feature/_attendance_/`, `web/src/features/attendance/`, [SPEC_ATTENDANCE_SYSTEM.md](../supabase/SPEC_ATTENDANCE_SYSTEM.md), `supabase/migrations/_attendance/`

---

## Настройки

### 🟢 Настройки приложения
Хаб, аккаунт, тема, «О приложении», ресурсы, архивы, сохранённые.  
Бизнес: [settings.md](settings.md)  
Техника: `_settings_/settings/`, `_settings_/settings_account/`, `_settings_/settings_about/`, … + `lib/core/theme/`

### 🟢 Сон аккаунта (hibernate)
Временно скрыть витрину; просыпание при входе. Не удаление / не wipe.  
Бизнес: [account-sleep.md](account-sleep.md)  
Техника: RPC `hibernate_account` / `wake_up_if_needed` · mobile + web settings + auth wake

### 🟢 Деактивация / удаление аккаунта
In-app «Деактивировать» = soft-hide (как сон): confirm → RPC `soft_delete_account` → выход. **Без** Auth cascade wipe.  
Безвозвратное удаление данных — через `/delete-account` §2 → support (обычно ≤ 30 дней).  
Бизнес: [account-delete.md](account-delete.md)  
Техника: `soft_delete_account` · `account_state = hibernate` · mobile + web · hard wipe вручную

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
Бизнес: [locations.md](locations.md) · гайд ресурсов: [resources-guide.md](resources-guide.md) · гайд всех сервисов: [services-guide.md](services-guide.md)  
Техника: `lib/feature/_catalog_/location/` · хаб `settings_resources` (+ web)

### 🔴 Привязка компании/точки к месту (план)
Точку записи и компанию посещаемости нельзя создать без `location`; занятое место — только через перенос. Плюс фильтр постов по местоположению (иконка). **Код не начат.**  
План: [entity-location-bind-plan.md](entity-location-bind-plan.md)

### 🟡 Отзывы по точкам записи (mock UI + SPEC)
На **профиль или адрес точки**; писать могут все (без гейта визита); вход с чужого профиля; один ответ хозяина; витрина = тег `feedback`; свой отзыв можно удалить. **Миграция ещё нет.**  
План: [point-reviews-plan.md](point-reviews-plan.md) · бэк: [SPEC_POINT_REVIEWS.md](../supabase/SPEC_POINT_REVIEWS.md) · mock: `lib/feature/_booking_/point_reviews/`

---

## Сводка одним взглядом

**🟢 Ок**  
Google-вход · Apple (iOS) · **сессия/выход** · онбординг · нижний бар · лента↔карта · **фильтры** · профиль · edit · теги · **подписчики** · публикации/ивенты · **реакции** · **комментарии** · **сохранённые** · **архивы** · **кластеры** · **чаты** · **уведомления** · **настройки** · **локации** · **онлайн-запись** · **бонусы** · **сон аккаунта** · **удаление аккаунта** · **посещаемость ядро** · **web-push** (нужен Firebase Web env на Vercel)

**🟡 Зазор**  
**блокировки** (UI + RPC + DM gate) · **сила тегов** (паттерн не везде одинаков) · сайт: chat reply/reactions/forward

**🔴 Дыра / блок**  
Phone OTP (отложено) · **бронь мест** (блок, не начинали)

### 🟡 Сайт (лендинг + кабинет)
Публичный Next.js в `web/`: лендинг, legal, auth, карта/профиль, создание поста (`/app/posts/new`). Догон мобилки — по фазам.
Бизнес: [website.md](website.md) · **карта:** [website-roadmap.md](website-roadmap.md) · [website-gap-plan.md](website-gap-plan.md)
Техника: `web/`

### 🟢 Админка сайта (скрытый вход)
15 тапов по «©» → `/admin` → хаб: Support · Аналитика · Honest Quiz.
Бизнес: [website-admin.md](website-admin.md) · Spec: [SPEC_ADMIN_PLATFORM.md](../supabase/SPEC_ADMIN_PLATFORM.md)
Техника: `web/src/app/admin/`, `/api/admin/{support,stats,honest-quiz}`, `SUPABASE_SERVICE_ROLE_KEY`

---

## Как обновлять

Новая фича — абзац со статусом 🟢 / 🟡 / 🔴.  
Появился бизнес-док или довели UI — смени цвет.
