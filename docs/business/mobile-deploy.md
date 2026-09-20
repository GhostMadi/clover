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

**Важно для FCM / push:** App Store provisioning profile (`BUILD_PROVISION_PROFILE_BASE64`) должен включать **Push Notifications** (`aps-environment=production`). Без этого TestFlight-сборка из CI не получает APNs/FCM token на устройстве.

## Signing (Xcode vs CI)

| Где | Как |
|-----|-----|
| **Xcode локально** | Release: **Automatically manage signing** (`project.pbxproj`) |
| **CI → TestFlight** | Manual override при `flutter build ipa` (Distribution + profile из secrets). **Не** `--no-codesign` — иначе entitlements (push) не вшиваются и FCM пустой |

Workflow проверяет в IPA `aps-environment=production` перед upload.

## Android / Play (AAB)

Play **не** принимает debug-подпись.

| Файл | Назначение |
|------|------------|
| `android/app/upload-keystore.jks` | Upload key (локально, **не** в git) |
| `android/key.properties` | пароли / alias (шаблон: `key.properties.example`) |
| `flutter build appbundle --release --dart-define-from-file=dart_defines.json` | → `build/app/outputs/bundle/release/app-release.aab` |

После первой загрузки в Play Console включи **Play App Signing**. SHA-1 **App signing** (из Play → Подписание приложения) добавь в Google Cloud Android OAuth / Firebase — иначе Google Sign-In на сборках из магазина может не работать.

## Где код

- Flutter: `lib/`, `android/`, `ios/`, `pubspec.yaml`
- Сайт не трогать «заодно», если задача только про мобилку (и наоборот)

## Связанные доки

- Продукт: [features-catalog.md](features-catalog.md)
- Сайт / дорожная карта веба: [website-roadmap.md](website-roadmap.md)
- Push / FCM: [../supabase/SPEC_PUSH_FCM.md](../supabase/SPEC_PUSH_FCM.md)
