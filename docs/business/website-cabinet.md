# Публичный сайт Clover (web) — кабинет после входа
**Статус:** черновик UI  
**Связано с:** [navigation-bars.md](navigation-bars.md), [website.md](website.md)

## Три раздела (как в приложении)

| Вкладка | Web route | Содержимое сейчас |
|---------|-----------|-------------------|
| **Лента** | `/app` | Городская лента + фильтры + пагинация скролла |
| **Карта** | `/app/map` | Тайлы + маркеры + «моя геолокация» + шторка поста |
| **Уведомления** | `/app/notifications` | Inbox (`list_notifications_enriched_cursor`) + пагинация; бейдж unread в rail |
| **Chat** | `/app/chat` | Список DM + тред `/app/chat/[id]` (`list_conversations_enriched` / `list_messages_enriched` / `send_message`) |
| **Profile** | `/app/profile` | Шапка + сетка + edit + **+** → `/app/posts/new` |

На десктопе — **левый rail** (иконки → подписи по hover); на мобилке — нижний бар + колокольчик в шапке.  
Карта — edge-to-edge.

**Запись** (`/app/settings/booking`): на десктопе — **workspace** (левый sub-nav + широкая зона до ~1200px), не узкая мобильная колонка; хаб = плитки + превью inbox. На мобилке — чипы-навигация сверху.

Скорость кабинета: middleware гейт через `getSession` (без Auth API на каждый таб), `loading.tsx` скелетон, prefetch вкладок, профиль — `Promise.all` (профиль + посты).

Догон мобилки: [website-gap-plan.md](website-gap-plan.md) — **8a/8b** 🟡; **8d Посещаемость** ✅ (хвосты: [website-attendance-gaps.md](website-attendance-gaps.md)).

## Яндекс.Карты

- Ключ из мобилки: `YandexMapKitConfig.apiKey` → `NEXT_PUBLIC_YANDEX_MAPS_API_KEY`
- Маркеры: RPC `list_markers_map` (центр + zoom → радиус как в мобилке)
- Если JS API отклонит MapKit-ключ — в кабинете Яндекса создай отдельный ключ **JavaScript API** с HTTP-реферерами `localhost:3000` и `clover.com.kz`
