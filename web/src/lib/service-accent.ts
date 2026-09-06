/** Акценты бизнес-сервисов = AppServiceKind / AppPalette. */

export type AppServiceKind = "resources" | "booking" | "attendance" | "bonus";

export type ServiceAccentClasses = {
  /** Мягкий фон иконок / секций */
  soft: string;
  /** Иконки и вторичный акцент */
  icon: string;
  /** Заливка CTA */
  cta: string;
  /** Текст на CTA */
  ctaFg: string;
  /** Обводка карточек */
  border: string;
};

export const SERVICE_ACCENT: Record<AppServiceKind, ServiceAccentClasses> = {
  resources: {
    soft: "bg-svc-resources",
    icon: "text-svc-resources-ink",
    cta: "bg-svc-resources-ink",
    ctaFg: "text-on-media",
    border: "border-svc-resources-ink/40",
  },
  booking: {
    soft: "bg-svc-booking",
    icon: "text-svc-booking-ink",
    /** Жёлтый soft + тёмно-коричневый текст — читаемо и в light, и в dark (ink не белеет). */
    cta: "bg-svc-booking",
    ctaFg: "text-svc-booking-ink",
    border: "border-svc-booking-ink/30",
  },
  attendance: {
    soft: "bg-svc-attendance",
    icon: "text-svc-attendance-ink",
    cta: "bg-svc-attendance-ink",
    ctaFg: "text-on-media",
    border: "border-svc-attendance-ink/40",
  },
  bonus: {
    soft: "bg-svc-bonus",
    icon: "text-svc-bonus-ink",
    cta: "bg-svc-bonus-ink",
    ctaFg: "text-on-media",
    border: "border-svc-bonus-ink/40",
  },
};

export function serviceTileIcon(kind: AppServiceKind): string {
  const a = SERVICE_ACCENT[kind];
  return `flex h-10 w-10 items-center justify-center rounded-[12px] ${a.soft} ${a.icon}`;
}

export function serviceCtaClasses(kind: AppServiceKind): string {
  const a = SERVICE_ACCENT[kind];
  return `${a.cta} ${a.ctaFg} hover:opacity-90 disabled:opacity-50 shadow-elevate-md`;
}
