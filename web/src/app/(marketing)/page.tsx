import Link from "next/link";
import { SITE } from "@/lib/site";

const nowServices = [
  {
    key: "marketing",
    tone: "brand" as const,
    label: "Маркетинг",
    title: "Посты и присутствие",
    text: "Публикации, карта событий и видимость в городе — чтобы о бизнесе узнавали.",
  },
  {
    key: "resources",
    tone: "resources" as const,
    label: "Ресурсы",
    title: "Фильтры и материалы",
    text: "Ресурсы вроде фильтров помогают оформлять посты и держать контент в одном стиле.",
  },
  {
    key: "booking",
    tone: "booking" as const,
    label: "Запись",
    title: "Управление записью",
    text: "Услуги, слоты и статусы визитов — сервис записи для клиентов и хозяев.",
  },
  {
    key: "attendance",
    tone: "attendance" as const,
    label: "Посещаемость",
    title: "Смены и отметки",
    text: "Сервис посещения: команда на месте, смены и контроль без хаоса в чатах.",
  },
] as const;

const upcoming = [
  {
    title: "Бронирование",
    text: "Отдельный крупный сервис бронирования — мажорная фича, детали уточним отдельно.",
  },
  {
    title: "Места и товары",
    text: "Фильтр по местам: понимать, где какие товары, и показывать это как удобный слой на карте и в ленте.",
  },
  {
    title: "Остатки",
    text: "Помогать видеть, сколько товара осталось — и показывать посты на странице с учётом наличия.",
  },
] as const;

const toneClass: Record<(typeof nowServices)[number]["tone"], string> = {
  brand: "bg-mint text-brand",
  resources: "bg-svc-resources text-svc-resources-ink",
  booking: "bg-svc-booking text-svc-booking-ink",
  attendance: "bg-svc-attendance text-svc-attendance-ink",
};

const barClass: Record<(typeof nowServices)[number]["tone"], string> = {
  brand: "bg-brand",
  resources: "bg-svc-resources-ink",
  booking: "bg-svc-booking-ink",
  attendance: "bg-svc-attendance-ink",
};

export default function HomePage() {
  return (
    <>
      <section className="relative overflow-hidden">
        <div aria-hidden className="hero-atmosphere pointer-events-none absolute inset-0" />
        <div
          aria-hidden
          className="hero-glow pointer-events-none absolute -right-16 top-8 h-[26rem] w-[26rem] rounded-full bg-brand-soft/50 blur-3xl"
        />

        <div className="relative mx-auto flex min-h-[calc(100vh-4.25rem)] max-w-6xl flex-col justify-center px-5 py-24 sm:px-8">
          <p className="anim-rise inline-flex w-fit items-center rounded-full bg-ink px-3.5 py-1.5 text-xs font-semibold tracking-wide text-on-media">
            {SITE.freeNote}
          </p>
          <p className="anim-rise anim-rise-delay-1 mt-8 font-display text-[clamp(3.2rem,11vw,6.5rem)] font-semibold leading-[0.92] tracking-tight text-ink">
            {SITE.name}
          </p>
          <h1 className="anim-rise anim-rise-delay-2 mt-7 max-w-2xl text-[clamp(1.35rem,3.2vw,2.05rem)] font-medium leading-snug text-ink">
            {SITE.tagline}
          </h1>
          <p className="anim-rise anim-rise-delay-3 mt-5 max-w-xl text-base leading-relaxed text-muted sm:text-lg">
            Один помощник вместо россыпи чатов и таблиц: развивать маркетинг, вести запись и посещаемость,
            публиковать посты с ресурсами. Для широкой аудитории — просто и по делу.
          </p>
          <div className="anim-rise anim-rise-delay-3 mt-10 flex flex-wrap gap-3">
            <Link
              href="/auth"
              className="inline-flex h-12 items-center rounded-[14px] bg-brand px-7 text-sm font-semibold text-ink shadow-elevate-brand transition hover:opacity-90"
            >
              Войти
            </Link>
            <a
              href="#services"
              className="inline-flex h-12 items-center rounded-[14px] border border-ink/10 bg-surface/85 px-7 text-sm font-semibold text-ink transition hover:border-brand"
            >
              Смотреть сервисы
            </a>
          </div>
        </div>
      </section>

      <section id="services" className="border-t border-line bg-surface">
        <div className="mx-auto max-w-6xl px-5 py-20 sm:px-8 sm:py-24">
          <p className="text-sm font-semibold tracking-[0.14em] text-brand uppercase">Уже в приложении</p>
          <h2 className="mt-3 max-w-2xl font-display text-3xl font-semibold tracking-tight text-ink sm:text-4xl">
            Сервисы, которые помогают вести дело
          </h2>
          <p className="mt-4 max-w-2xl text-muted">
            Каждый сервис — свой цвет и своя задача. Вместе они складываются в помощника для бизнеса, а не в
            разрозненные инструменты.
          </p>

          <ul className="mt-14 divide-y divide-line border-y border-line">
            {nowServices.map((item) => (
              <li key={item.key} className="grid gap-4 py-8 sm:grid-cols-[10rem_1fr] sm:gap-10 sm:py-9">
                <div>
                  <span className={`inline-flex rounded-full px-3 py-1 text-xs font-semibold ${toneClass[item.tone]}`}>
                    {item.label}
                  </span>
                  <div className={`mt-3 h-1 w-10 rounded-full ${barClass[item.tone]}`} aria-hidden />
                </div>
                <div>
                  <h3 className="text-xl font-semibold text-ink">{item.title}</h3>
                  <p className="mt-2 max-w-2xl text-[15px] leading-relaxed text-muted">{item.text}</p>
                </div>
              </li>
            ))}
          </ul>
        </div>
      </section>

      <section id="next" className="border-t border-line bg-ink text-on-media">
        <div className="mx-auto max-w-6xl px-5 py-20 sm:px-8 sm:py-24">
          <p className="text-sm font-semibold tracking-[0.14em] text-brand-soft uppercase">В планах</p>
          <h2 className="mt-3 max-w-2xl font-display text-3xl font-semibold tracking-tight sm:text-4xl">
            Следующие сервисы — та же идея
          </h2>
          <p className="mt-4 max-w-2xl text-on-media/65">
            Не новые «приложения рядом», а продолжение помощника: бронирование, места с товарами и остатки —
            чтобы страница и лента отражали реальность бизнеса.
          </p>

          <ol className="mt-12 space-y-8 border-t border-on-media/10 pt-10">
            {upcoming.map((item, i) => (
              <li key={item.title} className="grid gap-2 sm:grid-cols-[4rem_1fr] sm:gap-8">
                <span className="font-display text-sm font-semibold text-brand-soft">0{i + 1}</span>
                <div>
                  <h3 className="text-lg font-semibold">{item.title}</h3>
                  <p className="mt-2 max-w-2xl text-[15px] leading-relaxed text-on-media/60">{item.text}</p>
                </div>
              </li>
            ))}
          </ol>
        </div>
      </section>

      <section className="border-t border-line bg-mint/70">
        <div className="mx-auto max-w-6xl px-5 py-16 sm:px-8 sm:py-20">
          <h2 className="font-display text-2xl font-semibold tracking-tight text-ink sm:text-3xl">
            Для широкой аудитории — без сложного входа
          </h2>
          <p className="mt-4 max-w-2xl text-muted">
            Тот же вход, что в приложении: ник или email и пароль, регистрация по коду на почту, Google. Сейчас
            бесплатно — пробуйте сервисы в одном месте.
          </p>
          <div className="mt-8">
            <Link
              href="/auth"
              className="inline-flex h-12 items-center rounded-[14px] bg-surface px-7 text-sm font-semibold text-ink transition hover:opacity-90"
            >
              Авторизация
            </Link>
          </div>
        </div>
      </section>
    </>
  );
}
