# Чат — compact rounded conversational UI

**Статус:** UI-паттерн  
**Где:** `lib/feature/_chat_/chat_page/` · web `features/chat/components/chat-thread-view.tsx`  
**Цвета:** soft-акценты из Clover `AppPalette` (blue / orange / lilac / yellow / rose / cyan / mint) — не только green, не сырой hex  
**Геометрия:** язык из референса WA — мягкие углы, плотность, асимметрия

Seed (chatId) → стабильный peer-цвет. Свои bubbles — soft mint (`successSoft`). CTA send — `primary`.  
**Dark theme:** пузыри остаются candy light-пастелями («жвачка / мультик»), не тусклые dark softs.

---

## Язык

**rounded + compact + asymmetric**

Не Material «воздушные карточки» и не «всё BorderRadius.circular(20)».

| Элемент | Radius |
|---------|--------|
| Message bubble | 16–18 (хвост у края ~6) |
| Reply / quote внутри | 12–14 |
| Input (pill) | 24–28 |
| Avatar / FAB send | 50% |
| Small controls (+, icon) | 10–14 |
| Quote accent bar | 3 px слева |

---

## Композиция

1. **Bubble** — ширина по контенту (max ~78%), плотный padding 10–12, мало тени.  
2. **Reply** — карточка в карточке, меньший radius, inset, цветной left accent (brand / inverse на своих).  
3. **Асимметрия** — свои справа (soft mint), чужие слева (peer soft-акцент по seed).  
4. **Spacing** — между сообщениями 4–8; list horizontal 10–12; quote→text 6–8.  
5. **Composer** — `+` в цвете чата, поле pill, send круг `primary`.  
6. **Header / список** — аватар в soft-цвете чата.

Код: `chat_geometry.dart` · `chat_peer_accent.dart` · web `chat-accent.ts`.  
Фон смайликами: [../../business/chat-emoji-wallpaper.md](../../business/chat-emoji-wallpaper.md).

Связано: [adaptive-widgets.md](adaptive-widgets.md) · продукт [../../business/chats.md](../../business/chats.md)
