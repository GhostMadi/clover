/** Публичный сайт Clover — канонический домен и продуктовый тон. */
export const SITE = {
  name: "Clover",
  domain: "clover.com.kz",
  url: "https://clover.com.kz",
  email: "welcome@clover.com.kz",
  locale: "ru_KZ",
  /** Одна идея продукта для hero / SEO. */
  tagline: "Помощник для бизнеса — сервисы в одном приложении",
  description:
    "Clover помогает развивать маркетинг, вести запись и посещаемость, публиковать посты с ресурсами. Пока бесплатно. Официальный сайт clover.com.kz.",
  freeNote: "Сейчас — бесплатно для всех",
  /** Semver сайта (`web/package.json`), не билд Flutter. */
  webVersion: "0.1.0",
} as const;

/**
 * Акценты сервисов — только имена токенов из `globals.css` / AppPalette.
 * В UI: `bg-svc-booking`, `text-svc-booking-ink` и т.п. Hex здесь не дублируем.
 */
export const SERVICE_TONES = {
  brand: { soft: "mint", accent: "brand", ink: "ink" },
  booking: { soft: "svc-booking", accent: "svc-booking-ink", ink: "ink" },
  attendance: { soft: "svc-attendance", accent: "svc-attendance-ink", ink: "ink" },
  resources: { soft: "svc-resources", accent: "svc-resources-ink", ink: "on-media" },
  bonus: { soft: "svc-bonus", accent: "svc-bonus-ink", ink: "on-media" },
} as const;
