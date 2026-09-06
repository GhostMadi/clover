# Clover

Мобильное приложение (Flutter) и публичный сайт (Next.js) в одном репозитории.

## Структура

| Путь | Что |
|------|-----|
| `lib/` | Flutter-приложение |
| `supabase/` | миграции и Edge Functions |
| `docs/` | бизнес и бэк-доки |
| `web/` | сайт: лендинг, privacy, terms → позже кабинет |

## Мобилка

```bash
flutter pub get
flutter run
```

## Сайт

```bash
cd web
npm install
npm run dev
```

Открой http://localhost:3000

В Cursor открывай **корень** `clover` (или `clover.code-workspace`) — так виден и телефон, и сайт.
