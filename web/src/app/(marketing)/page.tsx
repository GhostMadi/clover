import Link from "next/link";
import { SITE } from "@/lib/site";

const services = [
  {
    key: "marketing",
    tone: "brand" as const,
    label: "Маркетинг",
    line: "Лента, карта событий, посты — видимость в городе",
  },
  {
    key: "resources",
    tone: "resources" as const,
    label: "Ресурсы",
    line: "Фильтры и материалы для оформления публикаций",
  },
  {
    key: "booking",
    tone: "booking" as const,
    label: "Запись",
    line: "Услуги, слоты, inbox визитов — для хозяина и клиента",
  },
  {
    key: "attendance",
    tone: "attendance" as const,
    label: "Посещаемость",
    line: "Смены, отметки, табель — без хаоса в чатах",
  },
] as const;

const toneSoft: Record<(typeof services)[number]["tone"], string> = {
  brand: "bg-mint text-brand",
  resources: "bg-svc-resources text-svc-resources-ink",
  booking: "bg-svc-booking text-svc-booking-ink",
  attendance: "bg-svc-attendance text-svc-attendance-ink",
};

export default function HomePage() {
  return (
    <section className="relative overflow-hidden">
      <div aria-hidden className="hero-atmosphere pointer-events-none absolute inset-0" />
      <div
        aria-hidden
        className="pointer-events-none absolute -right-20 top-0 h-72 w-72 rounded-full bg-brand-soft/40 blur-3xl"
      />

      <div className="relative mx-auto flex max-w-3xl flex-col px-5 py-10 sm:px-8 sm:py-14 lg:py-16">
        <p className="anim-rise text-[11px] font-semibold tracking-[0.16em] text-muted uppercase">
          {SITE.freeNote}
        </p>

        <p className="anim-rise anim-rise-delay-1 mt-4 font-display text-[clamp(2.75rem,10vw,4.5rem)] font-semibold leading-[0.95] tracking-tight text-ink">
          {SITE.name}
        </p>

        <h1 className="anim-rise anim-rise-delay-2 mt-4 max-w-xl text-[clamp(1.05rem,2.4vw,1.35rem)] font-medium leading-snug text-ink">
          {SITE.tagline}
        </h1>

        <p className="anim-rise anim-rise-delay-2 mt-3 max-w-lg text-[14px] leading-relaxed text-muted sm:text-[15px]">
          Маркетинг, запись, посещаемость и ресурсы — в одном входе. Без россыпи чатов и таблиц.
        </p>

        <div className="anim-rise anim-rise-delay-3 mt-7 flex flex-wrap items-center gap-3">
          <Link
            href="/auth"
            className="inline-flex h-11 items-center rounded-[14px] bg-brand px-6 text-sm font-semibold text-ink shadow-elevate-brand transition hover:opacity-90"
          >
            Войти
          </Link>
          <Link
            href="/auth/register"
            className="inline-flex h-11 items-center rounded-[14px] border border-line bg-surface/90 px-6 text-sm font-semibold text-ink transition hover:border-brand"
          >
            Регистрация
          </Link>
        </div>

        <ul
          id="services"
          className="anim-rise anim-rise-delay-3 mt-10 scroll-mt-24 divide-y divide-line border-y border-line"
        >
          {services.map((s) => (
            <li key={s.key} className="flex items-start gap-3 py-3.5 sm:gap-4 sm:py-4">
              <span
                className={`mt-0.5 shrink-0 rounded-full px-2.5 py-1 text-[11px] font-bold ${toneSoft[s.tone]}`}
              >
                {s.label}
              </span>
              <p className="min-w-0 text-[13px] leading-snug text-ink sm:text-[14px]">{s.line}</p>
            </li>
          ))}
        </ul>

        <p id="next" className="mt-6 scroll-mt-24 text-[12px] leading-relaxed text-muted sm:text-[13px]">
          <span className="font-semibold text-ink">Скоро:</span> бронь мест по схеме, места и товары,
          остатки — тот же помощник, без отдельных «приложений рядом». Вход: ник / email / Google.
        </p>
      </div>
    </section>
  );
}
