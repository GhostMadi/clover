import { CalendarDays, ClipboardList, Layers, MapPin } from "lucide-react";
import Image from "next/image";
import Link from "next/link";
import { EVENT_FILTER_EMOJIS } from "@/features/catalog/lib/event-emojis";
import { SITE } from "@/lib/site";

const services = [
  {
    key: "marketing",
    label: "Маркетинг",
    line: "Лента и карта — чтобы о вас узнавали в городе",
    Icon: MapPin,
    soft: "bg-mint",
    ink: "text-brand",
    bar: "bg-brand",
    delay: "landing-delay-1",
  },
  {
    key: "resources",
    label: "Ресурсы",
    line: "Фильтры и материалы для постов",
    Icon: Layers,
    soft: "bg-svc-resources",
    ink: "text-svc-resources-ink",
    bar: "bg-svc-resources-ink",
    delay: "landing-delay-2",
  },
  {
    key: "booking",
    label: "Запись",
    line: "Услуги, слоты и визиты в одном inbox",
    Icon: CalendarDays,
    soft: "bg-svc-booking",
    ink: "text-svc-booking-ink",
    bar: "bg-svc-booking",
    delay: "landing-delay-3",
  },
  {
    key: "attendance",
    label: "Посещаемость",
    line: "Смены и отметки без хаоса в чатах",
    Icon: ClipboardList,
    soft: "bg-svc-attendance",
    ink: "text-svc-attendance-ink",
    bar: "bg-svc-attendance-ink",
    delay: "landing-delay-4",
  },
] as const;

/** Раскладка как маркеры на карте: позиция + размер + лёгкий наклон. */
const BG_MARKERS: {
  emoji: (typeof EVENT_FILTER_EMOJIS)[number];
  top: string;
  left: string;
  size: string;
  rotate: string;
  delay: string;
}[] = [
  { emoji: "📍", top: "6%", left: "6%", size: "1.6rem", rotate: "-12deg", delay: "0s" },
  { emoji: "🎉", top: "10%", left: "78%", size: "1.85rem", rotate: "8deg", delay: "-1.2s" },
  { emoji: "☕", top: "18%", left: "88%", size: "1.35rem", rotate: "-6deg", delay: "-2.4s" },
  { emoji: "🎵", top: "22%", left: "4%", size: "1.5rem", rotate: "14deg", delay: "-0.6s" },
  { emoji: "🗺️", top: "8%", left: "42%", size: "1.4rem", rotate: "-4deg", delay: "-3.1s" },
  { emoji: "🎨", top: "38%", left: "92%", size: "1.55rem", rotate: "10deg", delay: "-1.8s" },
  { emoji: "🔥", top: "48%", left: "2%", size: "1.45rem", rotate: "-18deg", delay: "-4s" },
  { emoji: "🎭", top: "55%", left: "90%", size: "1.7rem", rotate: "6deg", delay: "-2.2s" },
  { emoji: "🍕", top: "68%", left: "8%", size: "1.5rem", rotate: "12deg", delay: "-0.9s" },
  { emoji: "✨", top: "72%", left: "86%", size: "1.35rem", rotate: "-8deg", delay: "-3.5s" },
  { emoji: "🏀", top: "82%", left: "18%", size: "1.4rem", rotate: "16deg", delay: "-1.5s" },
  { emoji: "🌿", top: "86%", left: "72%", size: "1.55rem", rotate: "-10deg", delay: "-2.8s" },
  { emoji: "🎤", top: "42%", left: "12%", size: "1.3rem", rotate: "5deg", delay: "-4.4s" },
  { emoji: "🎯", top: "30%", left: "70%", size: "1.25rem", rotate: "-14deg", delay: "-0.3s" },
  { emoji: "🌸", top: "62%", left: "48%", size: "1.2rem", rotate: "9deg", delay: "-3.8s" },
  { emoji: "🪩", top: "14%", left: "22%", size: "1.35rem", rotate: "-7deg", delay: "-2s" },
  { emoji: "⭐", top: "78%", left: "40%", size: "1.15rem", rotate: "4deg", delay: "-1.1s" },
  { emoji: "🌈", top: "90%", left: "55%", size: "1.45rem", rotate: "-5deg", delay: "-4.8s" },
];

export default function HomePage() {
  return (
    <section className="relative overflow-hidden bg-bg">
      <div aria-hidden className="pointer-events-none absolute inset-0 overflow-hidden">
        {BG_MARKERS.map((m) => (
          <span
            key={`${m.emoji}-${m.top}-${m.left}`}
            className="landing-emoji absolute select-none"
            style={{
              top: m.top,
              left: m.left,
              fontSize: m.size,
              transform: `rotate(${m.rotate})`,
              animationDelay: m.delay,
            }}
          >
            {m.emoji}
          </span>
        ))}
      </div>

      <div className="relative mx-auto max-w-3xl px-5 py-14 sm:px-8 sm:py-20">
        <div className="anim-rise flex items-center gap-4 sm:gap-5">
          <Image
            src="/logo.png"
            alt=""
            width={88}
            height={88}
            priority
            className="h-14 w-14 object-contain sm:h-[4.5rem] sm:w-[4.5rem]"
          />
          <p className="font-display text-[clamp(2.75rem,11vw,4.5rem)] font-semibold leading-none tracking-tight text-ink">
            {SITE.name}
          </p>
        </div>

        <h1 className="anim-rise anim-rise-delay-1 mt-5 max-w-md text-[clamp(1.1rem,2.6vw,1.35rem)] font-medium leading-snug text-ink">
          Помощник для бизнеса — всё нужное в одном приложении
        </h1>

        <div className="anim-rise anim-rise-delay-2 mt-8 flex flex-wrap gap-3">
          <Link
            href="/auth"
            className="landing-cta inline-flex h-11 items-center rounded-[14px] bg-brand px-6 text-sm font-semibold text-ink shadow-elevate-brand transition hover:opacity-90"
          >
            Войти
          </Link>
          <Link
            href="/auth/register"
            className="inline-flex h-11 items-center rounded-[14px] border border-line bg-surface px-6 text-sm font-semibold text-ink transition hover:border-brand hover:bg-mint"
          >
            Начать
          </Link>
        </div>

        <ul
          id="services"
          className="mt-14 grid scroll-mt-24 gap-3 sm:grid-cols-2 sm:gap-4"
        >
          {services.map((s) => {
            const Icon = s.Icon;
            return (
              <li
                key={s.key}
                className={`landing-card group relative overflow-hidden rounded-[18px] border border-line bg-surface p-4 ${s.delay}`}
              >
                <span
                  aria-hidden
                  className={`absolute left-0 top-0 h-full w-1 ${s.bar} opacity-0 transition group-hover:opacity-100`}
                />
                <div className="flex items-start gap-3">
                  <span
                    className={`landing-icon flex h-11 w-11 shrink-0 items-center justify-center rounded-[14px] ${s.soft} ${s.ink} transition duration-300 group-hover:-rotate-6 group-hover:scale-110`}
                  >
                    <Icon className="h-5 w-5" strokeWidth={2} />
                  </span>
                  <div className="min-w-0 pt-0.5">
                    <p className={`text-[14px] font-semibold ${s.ink}`}>{s.label}</p>
                    <p className="mt-1 text-[13px] leading-snug text-muted">{s.line}</p>
                  </div>
                </div>
              </li>
            );
          })}
        </ul>
      </div>
    </section>
  );
}
