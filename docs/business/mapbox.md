# Mapbox (карты Clover)

**Статус:** прод-конфиг  
**Зачем:** один справочник токенов и сборки после перехода с Yandex Maps.

## Токены

| Токен | Где | Scope |
|-------|-----|--------|
| Public `clover` | веб `NEXT_PUBLIC_MAPBOX_ACCESS_TOKEN` (Vercel + `web/.env.local`) | Styles / tiles в браузере |
| Public `clover_flutter` | `--dart-define=MAPBOX_ACCESS_TOKEN=…` / GitHub Secret `MAPBOX_ACCESS_TOKEN` | Мобилка |
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
Логотип Mapbox и attribution на карте скрыты.

## После смены токенов

1. Vercel env → Redeploy  
2. Мобилка: clean build / `pod install`  
3. Проверить лимиты на [account.mapbox.com](https://account.mapbox.com/)
