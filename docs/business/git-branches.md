# Ветки Git — main, mobile, web

**Статус:** рабочий процесс  
**Связано с:** [mobile-deploy.md](mobile-deploy.md) · [website-deploy.md](website-deploy.md)  
**Правила агента:** `.cursor/rules/clover-git-main.mdc`, `clover-mobile-git.mdc`, `clover-web-git.mdc`

## Роли веток

| Ветка | Роль |
|-------|------|
| **`main`** | Общий trunk: доки, контракты, то что нужно и мобилке и вебу. Не деплоит TestFlight и не Vercel-прод. |
| **`mobile-production`** | Прод мобилки → GitHub Actions → TestFlight / сторы |
| **`web-production`** | Прод сайта → Vercel → clover.com.kz |

## Периодический синхрон

После заметных коммитов в **`main`** (доки, общие правила, миграции-спеки, shared):

```bash
git checkout mobile-production && git pull && git merge main && git push origin mobile-production
git checkout web-production && git pull && git merge main && git push origin web-production
```

После заметных релизов в прод-ветках — обратно в **`main`**, чтобы trunk не отставал:

```bash
git checkout main && git pull
git merge mobile-production   # или cherry-pick нужного
git merge web-production
git push origin main
```

Конфликты `web/` vs `lib/` обычно редки; доки и `docs/` мержить спокойно.

## Когда что пушить

| Задача | Ветка |
|--------|--------|
| Релиз / фича мобилки | `mobile-production` |
| Релиз / фича сайта | `web-production` |
| Только доки / процесс / общий ориентир | сначала `main`, потом синхрон в обе прод-ветки |

## Не путать

- Не пушить мобильный прод в `web-production` и наоборот «заодно».  
- Не ждать деплоя сайта от `main` — Vercel слушает **`web-production`**.  
- TestFlight слушает **`mobile-production`**, не `main`.
