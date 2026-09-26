"use client";

import { ArrowLeft, type LucideIcon } from "lucide-react";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { useEffect, useState, type ReactNode } from "react";
import type { AppServiceKind } from "@/lib/service-accent";

export type ServiceWorkspaceNavItem = {
  href: string;
  label: string;
  match: (pathname: string) => boolean;
  Icon: LucideIcon;
  /** `main` — день/работа; `more` — низ rail (настройки, гайд…). */
  group?: "main" | "more";
  /** Действие вместо перехода (чат точки). */
  onSelect?: () => void;
  disabled?: boolean;
};

type ServiceWorkspaceShellProps = {
  service: AppServiceKind;
  brandTitle: string;
  brandSubtitle?: string;
  title: string;
  nav: readonly ServiceWorkspaceNavItem[];
  children: ReactNode;
  /** На мобилке: куда ведёт «назад» с не-хаба. */
  backHref?: string;
  /** Path хаба — с него «назад» ведёт в settings (или hubBackHref). */
  hubPath: string;
  hubBackHref?: string;
  /** CTA справа в шапке контента (кнопка «+» и т.п.). */
  trailing?: ReactNode;
  /** Одно предложение: что на этом экране. Desktop — под тайтлом, mobile — полоска под шапкой. */
  lead?: string;
  /** Точка / компания — в rail (md+) или полоска под шапкой (mobile). */
  entitySlot?: ReactNode;
  /** Короткое сообщение под навигацией (ошибка чата и т.п.). */
  navNote?: string;
  hideNav?: boolean;
  maxWidthClassName?: string;
};

const ASIDE_BG: Record<AppServiceKind, string> = {
  booking: "bg-surface-soft-green/40",
  attendance: "bg-svc-attendance/25",
  resources: "bg-svc-resources/25",
  bonus: "bg-surface-muted/40",
  venue: "bg-svc-venue/20",
};

const ACTIVE_CHIP: Record<AppServiceKind, string> = {
  booking: "bg-svc-booking text-svc-booking-ink",
  attendance: "bg-svc-attendance text-svc-attendance-ink",
  resources: "bg-svc-resources text-svc-resources-ink",
  bonus: "bg-svc-bonus text-svc-bonus-ink",
  venue: "bg-svc-venue text-svc-venue-ink",
};

const BACK_HOVER: Record<AppServiceKind, string> = {
  booking: "text-svc-booking-ink hover:bg-svc-booking",
  attendance: "text-svc-attendance-ink hover:bg-svc-attendance",
  resources: "text-svc-resources-ink hover:bg-svc-resources",
  bonus: "text-svc-bonus-ink hover:bg-svc-bonus",
  venue: "text-svc-venue-ink hover:bg-svc-venue",
};

const NAV_IDLE: Record<AppServiceKind, string> = {
  booking: "text-ink hover:bg-svc-booking/40",
  attendance: "text-ink hover:bg-svc-attendance/40",
  resources: "text-ink hover:bg-svc-resources/40",
  bonus: "text-ink hover:bg-svc-bonus/40",
  venue: "text-ink hover:bg-svc-venue/40",
};

const BRAND_INK: Record<AppServiceKind, string> = {
  booking: "text-svc-booking-ink",
  attendance: "text-svc-attendance-ink",
  resources: "text-svc-resources-ink",
  bonus: "text-svc-bonus-ink",
  venue: "text-svc-venue-ink",
};

function useIsMd(): boolean {
  const [md, setMd] = useState(false);
  useEffect(() => {
    const mq = window.matchMedia("(min-width: 768px)");
    const apply = () => setMd(mq.matches);
    apply();
    mq.addEventListener("change", apply);
    return () => mq.removeEventListener("change", apply);
  }, []);
  return md;
}

function NavLinks({
  items,
  service,
  pathname,
  compact,
}: {
  items: readonly ServiceWorkspaceNavItem[];
  service: AppServiceKind;
  pathname: string;
  compact?: boolean;
}) {
  return (
    <>
      {items.map(({ href, label, match, Icon, onSelect, disabled }) => {
        const active = match(pathname);
        const className = compact
          ? `flex shrink-0 items-center gap-2 rounded-[14px] px-3 py-1.5 text-[12px] font-bold transition disabled:opacity-60 ${
              active
                ? ACTIVE_CHIP[service]
                : "border border-line text-muted hover:bg-surface-muted"
            }`
          : `flex w-full items-center gap-2.5 rounded-[12px] px-2.5 py-2.5 text-left text-[13px] font-semibold transition disabled:opacity-60 ${
              active ? ACTIVE_CHIP[service] : NAV_IDLE[service]
            }`;
        const body = (
          <>
            <Icon
              className={compact ? "h-3.5 w-3.5" : "h-4 w-4 shrink-0"}
              strokeWidth={2}
            />
            {label}
          </>
        );
        if (onSelect) {
          return (
            <button
              key={label}
              type="button"
              onClick={onSelect}
              disabled={disabled}
              className={className}
            >
              {body}
            </button>
          );
        }
        return (
          <Link key={href} href={href} className={className}>
            {body}
          </Link>
        );
      })}
    </>
  );
}

/**
 * Единый workspace хозяина для Записи / Посещаемости / Ресурсов.
 *
 * md+: rail слева (бренд → entity → nav) · контент справа.
 * mobile: назад + title · entity · чипы · контент.
 *
 * См. docs/business/website-host-desktop.md
 */
export function ServiceWorkspaceShell({
  service,
  brandTitle,
  brandSubtitle = "Рабочий стол хозяина",
  title,
  nav,
  children,
  backHref,
  hubPath,
  hubBackHref = "/app/settings",
  trailing,
  lead,
  entitySlot,
  navNote,
  hideNav = false,
  maxWidthClassName = "max-w-[1400px]",
}: ServiceWorkspaceShellProps) {
  const pathname = usePathname();
  const isMd = useIsMd();
  const isHub = pathname === hubPath;
  const mobileBack = isHub ? hubBackHref : (backHref ?? hubPath);

  const mainNav = nav.filter((i) => (i.group ?? "main") === "main");
  const moreNav = nav.filter((i) => i.group === "more");
  const allForChips = [...mainNav, ...moreNav];

  return (
    <div className="min-h-[calc(100dvh-3rem-4.25rem)] bg-bg md:min-h-dvh">
      <div className={`mx-auto w-full ${maxWidthClassName}`}>
        <header className="sticky top-0 z-10 flex h-12 items-center gap-2 border-b border-line bg-bg px-2 md:hidden">
          <Link
            href={mobileBack}
            className={`flex h-10 w-10 items-center justify-center rounded-full ${BACK_HOVER[service]}`}
            aria-label="Назад"
          >
            <ArrowLeft className="h-5 w-5" strokeWidth={2} />
          </Link>
          <h1 className={`min-w-0 flex-1 truncate text-[16px] font-bold ${BRAND_INK[service]}`}>
            {title}
          </h1>
          {trailing}
        </header>

        {lead ? (
          <p className="border-b border-line px-4 py-2 text-[13px] leading-snug text-muted md:hidden">
            {lead}
          </p>
        ) : null}

        {entitySlot && !isMd ? (
          <div className="border-b border-line px-3 py-2">{entitySlot}</div>
        ) : null}

        {!hideNav && allForChips.length > 0 ? (
          <nav className="flex gap-2 overflow-x-auto border-b border-line px-3 py-2.5 md:hidden">
            <NavLinks items={allForChips} service={service} pathname={pathname} compact />
          </nav>
        ) : null}

        <div className="md:flex md:min-h-dvh md:gap-0">
          {!hideNav ? (
            <aside
              className={`hidden w-[240px] shrink-0 border-r border-line md:block ${ASIDE_BG[service]}`}
            >
              <div className="sticky top-0 flex max-h-dvh flex-col gap-4 overflow-y-auto px-3 py-5">
                <div>
                  <p
                    className={`mb-0.5 px-2 font-display text-[18px] font-semibold ${BRAND_INK[service]}`}
                  >
                    {brandTitle}
                  </p>
                  <p className="px-2 text-[11px] text-muted">{brandSubtitle}</p>
                </div>

                {entitySlot && isMd ? (
                  <div className="px-0.5 [&_button]:w-full [&_button]:max-w-none">
                    {entitySlot}
                  </div>
                ) : null}

                {navNote ? (
                  <p className="px-2 text-[12px] text-destructive">{navNote}</p>
                ) : null}

                {mainNav.length > 0 ? (
                  <ul className="space-y-0.5">
                    {mainNav.map((item) => (
                      <li key={item.href}>
                        <NavLinks
                          items={[item]}
                          service={service}
                          pathname={pathname}
                        />
                      </li>
                    ))}
                  </ul>
                ) : null}

                {moreNav.length > 0 ? (
                  <div>
                    <p className="mb-1.5 px-2 text-[10px] font-bold uppercase tracking-wide text-muted">
                      Ещё
                    </p>
                    <ul className="space-y-0.5">
                      {moreNav.map((item) => (
                        <li key={item.href}>
                          <NavLinks
                            items={[item]}
                            service={service}
                            pathname={pathname}
                          />
                        </li>
                      ))}
                    </ul>
                  </div>
                ) : null}
              </div>
            </aside>
          ) : null}

          <div className="min-w-0 flex-1">
            <div className="hidden items-center gap-3 border-b border-line px-6 py-4 md:flex">
              <div className="min-w-0 flex-1">
                <p
                  className={`text-[12px] font-bold uppercase tracking-wide ${BRAND_INK[service]}`}
                >
                  {brandTitle}
                </p>
                <h1 className="font-display text-[22px] font-semibold text-ink">{title}</h1>
                {lead ? (
                  <p className="mt-1 max-w-2xl text-[13px] font-normal leading-snug text-muted">
                    {lead}
                  </p>
                ) : null}
              </div>
              {trailing}
            </div>
            <div className="px-4 py-4 md:px-6 md:py-5">{children}</div>
          </div>
        </div>
      </div>
    </div>
  );
}
