# JSON схемы пространства — полный контракт для AI / вставки

**Связано:** [space-plan-resources.md](space-plan-resources.md) · [venue-seating.md](venue-seating.md)  
**Короткий product-пример:** [venue-plan.example.json](venue-plan.example.json)  
**Полный эталон (все kind + 2 этажа):** [venue-plan.full.example.json](venue-plan.full.example.json)

**Промпт с плейсхолдерами «вставь своё»:** [venue-plan-ai-prompt.md](venue-plan-ai-prompt.md)

В редакторе сайта: **Файл → Вставить JSON → «Подставить полный пример»**.

---

## Два формата

| Формат | Когда | Корень |
|--------|--------|--------|
| **Здание (редактор)** | Вставка в рисовалку, localStorage | `{ version, floors[], activeFloorKey }` |
| **Product-envelope** | Документ для мобилки / витрины | `{ schema_version, plan, bookables, occasion?, inventory? }` |

Импорт на сайте принимает **оба** (+ snake_case у узлов). Для AI удобнее отдавать **формат здания** из full.example.

---

## Шпаргалка для промпта

```
Сгенерируй JSON здания Clover (version:1, floors, activeFloorKey).
Этаж: id, floorKey, label, version, status, canvas{width,height,background}, nodes[].
kind: rect|ellipse|line|polygon|path|emoji|text.
role: decor | bookable (у bookable обязателен bookableId).
frame {x,y,w,h} для rect/ellipse/emoji/text.
points[] для line/polygon/path; holes[][] опц. у path.
rotation, groupId опционально.
style: fill (null ок), stroke, strokeWidth, radius, opacity.
zIndex число. Координаты в px внутри canvas.
Не клади inventory внутрь nodes.
Ориентир: venue-plan.full.example.json
```

---

## Что покрывает полный пример

| Возможность | В примере |
|-------------|-----------|
| 2 этажа | floor_1 / floor_2 |
| rect / ellipse | стол, VIP, кабина |
| line | разделитель, перила |
| polygon | зона лаунж |
| path + holes | контур + «колонна» с дырой |
| emoji / text | кухня, WC, подписи |
| groupId | стол + стулья **или** связка emoji (несколько смайлов = одно визуальное место) |
| rotation | VIP |
| decor vs bookable | бар/сцена vs столы |

### 🌈 Emoji chaos (отдельный эталон)

Сумасшедший 2-этажный парк: карнавал + cosmic lounge, десятки emoji, яркие bookable-зоны (фудкорт, танцпол, VIP-облако, планеты).

В UI: **Ресурсы → Схемы → «Emoji chaos»** или в редакторе шаблон / «Вставить JSON → Emoji chaos».

Код: `web/src/features/venue/lib/plan-crazy-emoji-example.ts`

Занятость (`inventory`) на холст не пишется — подмешивается при показе гостю.
