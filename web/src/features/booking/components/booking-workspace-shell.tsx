"use client";

import {
  ArrowLeft,
  BarChart3,
  CalendarDays,
  ClipboardList,
  LayoutGrid,
  Scissors,
  Settings2,
} from "lucide-react";
import Link from "next/link";
import { usePathname } from "next/navigation";
import type { ReactNode } from "react";

const NAV = [
  {
    href: "/app/settings/booking",
    label: "Обзор",
    match: (p: string) => p === "/app/settings/booking",
    Icon: LayoutGrid,
  },
  {
    href: "/app/settings/booking/inbox",
    label: "Мои записи",
    match: (p: string) => p.startsWith("/app/settings/booking/inbox"),
    Icon: ClipboardList,
  },
  {
    href: "/app/settings/booking/services",
    label: "Услуги",
    match: (p: string) => p.startsWith("/app/settings/booking/services"),
    Icon: Scissors,
  },
  {
    href: "/app/settings/booking/schedule",
    label: "Расписание",
    match: (p: string) => p.startsWith("/app/settings/booking/schedule"),
    Icon: Settings2,
  },
  {
    href: "/app/settings/booking/analytics",
    label: "Аналитика",
    match: (p: string) => p.startsWith("/app/settings/booking/analytics"),
    Icon: BarChart3,
  },
  {
    href: "/app/settings/booking/my",
    label: "Мои бронирования",
    match: (p: string) => p.startsWith("/app/settings/booking/my"),
    Icon: CalendarDays,
  },
] as const;

type BookingWorkspaceShellProps = {
  title: string;
  children: ReactNode;
  /** На мобилке: куда ведёт «назад». На хабе — в настройки. */
  backHref?: string;
  trailing?: ReactNode;
  /** Скрыть sub-nav (редко; по умолчанию показан). */
  hideNav?: boolean;
};

/**
 * Широкий workspace раздела «Запись» на десктопе (sub-nav + контент).
 * На мобилке — компактная шапка как у настроек.
 */
export function BookingWorkspaceShell({
  title,
  children,
  backHref = "/app/settings/booking",
  trailing,
  hideNav = false,
}: BookingWorkspaceShellProps) {
  const pathname = usePathname();
  const isHub = pathname === "/app/settings/booking";
  const mobileBack = isHub ? "/app/settings" : backHref;

  return (
    <div className="min-h-[calc(100dvh-3rem-4.25rem)] bg-bg md:min-h-dvh">
      <div className="mx-auto w-full max-w-[1200px]">
        {/* Mobile header */}
        <header className="sticky top-0 z-10 flex h-12 items-center gap-2 border-b border-line bg-bg px-2 md:hidden">
          <Link
            href={mobileBack}
            className="flex h-10 w-10 items-center justify-center rounded-full text-svc-booking-ink hover:bg-svc-booking"
            aria-label="Назад"
          >
            <ArrowLeft className="h-5 w-5" strokeWidth={2} />
          </Link>
          <h1 className="min-w-0 flex-1 truncate text-[16px] font-bold text-svc-booking-ink">
            {title}
          </h1>
          {trailing}
        </header>

        {/* Mobile horizontal nav chips */}
        {!hideNav ? (
          <nav className="flex gap-1.5 overflow-x-auto border-b border-line px-3 py-2 md:hidden">
            {NAV.map(({ href, label, match, Icon }) => {
              const active = match(pathname);
              return (
                <Link
                  key={href}
                  href={href}
                  className={`flex shrink-0 items-center gap-1.5 rounded-full px-3 py-1.5 text-[12px] font-bold transition ${
                    active
                      ? "bg-svc-booking text-svc-booking-ink"
                      : "border border-line text-muted hover:bg-surface-muted"
                  }`}
                >
                  <Icon className="h-3.5 w-3.5" strokeWidth={2} />
                  {label}
                </Link>
              );
            })}
          </nav>
        ) : null}

        <div className="md:flex md:min-h-[calc(100dvh-0px)] md:gap-0">
          {/* Desktop sub-nav */}
          {!hideNav ? (
            <aside className="hidden w-[220px] shrink-0 border-r border-line bg-surface-soft-green/40 md:block">
              <div className="sticky top-0 px-3 py-5">
                <p className="mb-1 px-2 font-display text-[18px] font-semibold text-svc-booking-ink">
                  Запись
                </p>
                <p className="mb-4 px-2 text-[11px] text-muted">Рабочий стол хозяина</p>
                <ul className="space-y-0.5">
                  {NAV.map(({ href, label, match, Icon }) => {
                    const active = match(pathname);
                    return (
                      <li key={href}>
                        <Link
                          href={href}
                          className={`flex items-center gap-2.5 rounded-[12px] px-2.5 py-2.5 text-[13px] font-semibold transition ${
                            active
                              ? "bg-svc-booking text-svc-booking-ink"
                              : "text-ink hover:bg-svc-booking/40"
                          }`}
                        >
                          <Icon className="h-4 w-4 shrink-0" strokeWidth={2} />
                          {label}
                        </Link>
                      </li>
                    );
                  })}
                </ul>
              </div>
            </aside>
          ) : null}

          <div className="min-w-0 flex-1">
            {/* Desktop page title */}
            <div className="hidden items-center gap-3 border-b border-line px-6 py-4 md:flex">
              <h1 className="min-w-0 flex-1 font-display text-[22px] font-semibold text-ink">
                {title}
              </h1>
              {trailing}
            </div>
            <div className="px-4 py-4 md:px-6 md:py-5">{children}</div>
          </div>
        </div>
      </div>
    </div>
  );
}
