# Mapbox (карты Clover)

**Статус:** прод-конфиг  
**Зачем:** один справочник токенов и сборки после перехода с Yandex Maps.

## Токены

| Токен | Где | Scope |
|-------|-----|--------|
| Public `clover` | веб `NEXT_PUBLIC_MAPBOX_ACCESS_TOKEN` (Vercel + `web/.env.local`) | Styles / tiles в браузере |
| Public `clover_flutter` | `--dart-define=MAPBOX_ACCESS_TOKEN=…` / GitHub Secret `MAPBOX_ACCESS_TOKEN` | Мобилка |

Локально (Cursor / VS Code): скопируй `dart_defines.json.example` → `dart_defines.json`, вставь `pk.` токен `clover_flutter`, запускай конфиг **clover (debug + Mapbox)**. Без этого карта даёт **HTTP 401 Invalid Token**.

| Secret (`DOWNLOADS:READ`) | **не в git** — `~/.netrc` + `android/gradle.properties` → `SDK_REGISTRY_TOKEN` | Скачивание iOS/Android SDK |

URL-ограничения для веб-токена: `http://localhost:3000`, `https://clover.com.kz`, `https://www.clover.com.kz`.

## Локальная настройка secret

**iOS / CocoaPods** — `~/.netrc`:

```
machine api.mapbox.com
login mapbox
password sk.YOUR_SECRET_WITH_DOWNLOADS_READ
```

`chmod 600 ~/.netrc`

**Android** — в `android/gradle.properties` (локально):

```
SDK_REGISTRY_TOKEN=sk.YOUR_SECRET_WITH_DOWNLOADS_READ
```

В CI (TestFlight): GitHub Secret `SDK_REGISTRY_TOKEN` + проброс в env job; для iOS — `.netrc` на runner перед `pod install`.

## Код

| Платформа | Точка входа |
|-----------|-------------|
| Flutter | `AppMap` → `mapbox_maps_flutter` (`lib/core/shared/app_map/`) |
| Web feed map | `web/src/features/cabinet/components/mapbox-map.tsx` |
| Web pin / geofence | `web/src/features/maps/mapbox-pin-map.tsx` |

Стиль всегда: `mapbox://styles/mapbox/standard`.  
Цветовая тема basemap: **`default`**.  
Светлая / тёмная приложения: `lightPreset` `day` / `night` (ночь с огнями зданий).  
Flutter: preset только после `onStyleLoadedListener` (раньше → `Import 'basemap' does not exist`).  
Логотип Mapbox и attribution на карте скрыты.

## Маркеры (LOD / clustering)

| Zoom | Данные | Рендер |
|------|--------|--------|
| &lt; 13 | RPC `list_markers_map_clusters` (PostGIS grid) | emoji + count chip |
| ≥ 13 | RPC `list_markers_map` (точки) | emoji-маркеры |

- **Flutter** `AppMap`: точки и серверные кластеры → `PointAnnotationManager` + PNG из icon factory (emoji в центре). Число кластера — chip сбоку, не вместо emoji. Sync аннотаций **инкрементальный** (diff create/delete/update). Mapbox SDK на мобилке не рисует цветные emoji через `text-field` (SDF) — поэтому PNG.
- **Web** `mapbox-map.tsx`: тот же контракт данных. **Server clusters** (`point_count ≥ 1`) → HTML `mapboxgl.Marker` (DOM: emoji + зелёный chip) — в браузере emoji нативны, быстрее чем Flutter PNG. **Точки** (≥ 13) → GeoJSON SymbolLayer + circle bg; клиентский proximity-cluster Mapbox — circle + число (нет sample emoji у агрегата).
- Prefetch соседних viewport (N/S/E/W ≈ 0.5 радиуса) → memory + disk cache.
- Точки копятся в in-memory пуле по id: при pan **назад** маркеры сразу из памяти. Debounce idle ~280ms.
- Стопка на точке: `get_posts_enriched(uuid[])` — один RPC на все посты (не N× `get_post_enriched`).

### Первый визит в новый район ждёт сеть (это норма)

Кэш отвечает только за **уже виденные** viewport (и prefetch соседей). Если пользователь уехал в район, которого ещё не было ни в memory, ни на диске — клиент обязан сходить в RPC. Это не баг и не «медленная карта»: без сети нельзя угадать маркеры. После ответа данные кладутся в пул/диск → повторный pan туда — мгновенно.

### Phase 3 — Vector tiles (MVT) маркеров

**Сейчас (Phases 1–2):** bbox RPC + GeoJSON/annotations. Хватает для текущей плотности.

**Phase 3 (позже, не в этом релизе):** бэк отдаёт **vector tiles** маркеров (MVT по z/x/y), клиент кладёт `vector` source в Mapbox вместо повторных bbox-RPC при каждом pan. Плюсы: меньше payload на больших zoom, CDN-кэш тайлов, плавный pan по городу. Минусы: инфра (tile server / `ST_AsMVT` + storage/CDN), инвалидация при create/update маркера, отдельный пайплайн для mobile и web.

Делать Phase 3 имеет смысл, когда bbox+prefetch упирается в latency/лимиты (много маркеров, частые pan по всему городу). До этого — не фейкать VTiles: остаёмся на LOD RPC.

## После смены токенов

1. Vercel env → Redeploy  
2. Мобилка: clean build / `pod install`  
3. Проверить лимиты на [account.mapbox.com](https://account.mapbox.com/)
