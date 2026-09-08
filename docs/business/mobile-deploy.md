# Деплой мобилки (Flutter → TestFlight)

Мобилка и сайт **изолированы по веткам**.

| Ветка | Что |
|-------|-----|
| **`mobile-production`** | Production-ready Flutter / iOS / Android → GitHub Actions → TestFlight |
| **`web-production`** | Сайт → Vercel (`clover.com.kz`) — см. [website-deploy.md](website-deploy.md) |
| **`main`** | Общий trunk / доки; **не** триггерит TestFlight и не веб-прод |

Правила агента: `.cursor/rules/clover-mobile-git.mdc`.

## Git → GitHub Actions

Workflow: [`.github/workflows/deploy_testflight.yml`](../../.github/workflows/deploy_testflight.yml)

```yaml
on:
  push:
    branches:
      - mobile-production
```

```bash
git checkout mobile-production
git add …   # без secrets / .env / keystores
git commit -m "feat(mobile): …"
git push origin mobile-production
```

## Secrets (GitHub → Settings → Secrets)

Нужны для workflow (имена как в YAML): сертификат, provisioning profile, App Store Connect API key и т.д.  
Не коммитить в репо.

## Где код

- Flutter: `lib/`, `android/`, `ios/`, `pubspec.yaml`
- Сайт не трогать «заодно», если задача только про мобилку (и наоборот)

## Связанные доки

- Продукт: [features-catalog.md](features-catalog.md)
- Сайт / дорожная карта веба: [website-roadmap.md](website-roadmap.md)
