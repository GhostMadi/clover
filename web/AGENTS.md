# AGENTS — Clover Web

Этот каталог (`web/`) ведёт агент Cursor по правилам в корне репо:

`.cursor/rules/clover-web-*.mdc`

Мобилка — `lib/` + `clover-*.mdc` без `-web-`. Бэк общий: `supabase/`, `docs/supabase/`.

Не проси пользователя выбирать стек/пакеты: следуй `clover-web-stack` и чеклисту.

Веб-прод: ветка **`web-production`** (`clover-web-git.mdc`) — не пуш веб-релиза в `main` без явной просьбы.

<!-- BEGIN:nextjs-agent-rules -->

# This is NOT the Next.js you know

This version has breaking changes — APIs, conventions, and file structure may all differ from your training data. Read the relevant guide in `node_modules/next/dist/docs/` (resolved from this file's directory; in monorepos the `next` package may not be visible from the repo root) before writing any code. Heed deprecation notices.

This block is written and re-added by `next dev` — verify at `node_modules/next/dist/server/lib/generate-agent-files.js`. Removing it from a diff only re-creates the uncommitted change; committing it with your work keeps the tree clean.

<!-- END:nextjs-agent-rules -->
