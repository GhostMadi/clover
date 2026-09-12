# Публичный сайт Clover (web) — кабинет после входа
**Статус:** черновик UI  
**Связано с:** [navigation-bars.md](navigation-bars.md), [website.md](website.md)

## Три раздела (как в приложении)

| Вкладка | Web route | Содержимое сейчас |
|---------|-----------|-------------------|
| **Лента** | `/app` | Городская лента + фильтры + пагинация скролла |
| **Карта** | `/app/map` | Тайлы + маркеры + «моя геолокация» + шторка поста |
| **Уведомления** | `/app/notifications` | Inbox (`list_notifications_enriched_cursor`) + пагинация; бейдж unread в rail |
| **Chat** | `/app/chat` | Список DM + тред `/app/chat/[id]`; бейдж unread в rail/нижнем баре (`count_unread_chat_messages`); список обновляется после `mark_conversation_read` |
| **Profile** | `/app/profile` | Шапка + сетка + edit + **+** → `/app/posts/new` |

На десктопе — **левый rail** (иконки → подписи по hover); на мобилке — нижний бар + колокольчик в шапке.  
Карта — edge-to-edge.

**Запись / Посещаемость / Ресурсы** — на десктопе **ServiceWorkspaceShell** (sub-nav + зона ~1400px): [website-host-desktop.md](website-host-desktop.md).  
Запись: inbox master–detail. Посещаемость: экран «Сегодня» по компании. Ресурсы: локации + превью карты. На мобилке — чипы сверху.

Скорость кабинета: middleware гейт через `getSession` (без Auth API на каждый таб), `loading.tsx` скелетон, prefetch вкладок, профиль — `Promise.all` (профиль + посты).

Догон мобилки: [website-gap-plan.md](website-gap-plan.md) — **8a/8b** desktop 🟢 (клиентские хвосты 🟡); **8d** ✅ (хвосты: [website-attendance-gaps.md](website-attendance-gaps.md)).  
Дорожная карта сайта: [website-roadmap.md](website-roadmap.md).

## Mapbox

- Веб: `NEXT_PUBLIC_MAPBOX_ACCESS_TOKEN` (public token `clover`) + стиль `mapbox://styles/mapbox/streets-v12`
- Мобилка: `MapboxConfig.accessToken` (public token `clover_flutter`) через `MapboxOptions.setAccessToken` в `main.dart`
- Маркеры: RPC `list_markers_map` (центр + zoom → радиус как в мобилке)
- Секрет с `DOWNLOADS:READ` — только локально / CI (`~/.netrc`, `SDK_REGISTRY_TOKEN`), см. [mapbox.md](mapbox.md)
- URL-ограничения веб-токена: `localhost:3000`, `clover.com.kz`, `www.clover.com.kz`
