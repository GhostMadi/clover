# Clover Web

Публичный сайт Clover (Next.js): лендинг и юридические страницы. Позже — веб-кабинет рядом с мобильным приложением.

## Стек

- Next.js (App Router) + TypeScript + Tailwind CSS v4
- Шрифты: Sora (бренд/заголовки), Manrope (текст) — как в мобильном UI

## Команды

```bash
cd web
npm install
npm run dev
```

Открой [http://localhost:3000](http://localhost:3000).

- `/` — лендинг
- `/privacy` — политика конфиденциальности
- `/terms` — условия использования

## Правила разработки

Смотри `.cursor/rules/clover-web-*.mdc` в корне репо. Кратко:

1. Сначала `docs/business/` (+ supabase при данных)
2. Код только в `web/`
3. Пакеты — по `clover-web-stack` (не MUI/random kits)
4. Тот же контракт бэка и EN-ключи, что мобилка
5. Перед сдачей: `npm run build`

Пользователь может не знать веб-стек — агент выбирает пакеты и структуру сам по правилам.
