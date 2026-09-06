"use client";

import {
  Bell,
  Building2,
  CalendarDays,
  ExternalLink,
  FolderPlus,
  House,
  Layers,
  Map as MapIcon,
  MessageCircle,
  Plus,
  Settings,
  UserRound,
} from "lucide-react";
import Image from "next/image";
import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import { useEffect, useState } from "react";
import {
  ATTENDANCE_SHORTCUT_EVENT,
  readAttendanceShortcut,
} from "@/features/attendance/lib/shortcut-prefs";
import {
  BOOKING_SHORTCUT_EVENT,
  readBookingShortcut,
} from "@/features/booking/lib/shortcut-prefs";
import { countUnreadNotifications } from "@/features/notifications/lib/notifications-api";
import {
  readResourcesShortcut,
  RESOURCES_SHORTCUT_EVENT,
} from "@/features/resources/lib/shortcut-prefs";
import { createClient } from "@/lib/supabase/client";
import { SITE } from "@/lib/site";

const links = [
  {
    href: "/app",
    label: "Лента",
    match: (p: string) => p === "/app",
    Icon: House,
  },
  {
    href: "/app/map",
    label: "Карта",
    match: (p: string) => p.startsWith("/app/map"),
    Icon: MapIcon,
  },
  {
    href: "/app/notifications",
    label: "Уведомления",
    match: (p: string) => p.startsWith("/app/notifications"),
    Icon: Bell,
    badge: true,
  },
  {
    href: "/app/chat",
    label: "Чаты",
    match: (p: string) => p.startsWith("/app/chat"),
    Icon: MessageCircle,
  },
  {
    href: "/app/profile",
    label: "Профиль",
    match: (p: string) => p.startsWith("/app/profile"),
    Icon: UserRound,
  },
] as const;

/** Кабинет: слева rail как Instagram (иконки → подписи по hover), на мобилке — низ. */
export function CabinetShell({ children }: { children: React.ReactNode }) {
  const pathname = usePathname();
  const router = useRouter();
  const [unread, setUnread] = useState(0);
  const [userId, setUserId] = useState<string | null>(null);
  const [resourcesShortcut, setResourcesShortcut] = useState(false);
  const [bookingShortcut, setBookingShortcut] = useState(false);
  const [attendanceShortcut, setAttendanceShortcut] = useState(false);
  const [addOpen, setAddOpen] = useState(false);
  const mapFullBleed = pathname.startsWith("/app/map");
  const feedFullBleed =
    pathname === "/app" ||
    pathname.startsWith("/app/profile") ||
    pathname.startsWith("/app/u/") ||
    pathname.startsWith("/app/posts/") ||
    pathname.startsWith("/app/notifications") ||
    pathname.startsWith("/app/chat") ||
    pathname.startsWith("/app/settings") ||
    pathname.startsWith("/app/attendance") ||
    pathname.startsWith("/app/clusters");
  const resourcesActive = pathname.startsWith("/app/settings/resources");
  const bookingActive = pathname.startsWith("/app/settings/booking");
  const attendanceActive =
    pathname.startsWith("/app/settings/attendance") ||
    pathname.startsWith("/app/attendance");
  const settingsActive =
    pathname.startsWith("/app/settings") &&
    !resourcesActive &&
    !bookingActive &&
    !pathname.startsWith("/app/settings/attendance");
  const createActive =
    pathname.startsWith("/app/posts/new") || pathname.startsWith("/app/clusters/new");
  const onOwnProfile =
    pathname === "/app/profile" || pathname.startsWith("/app/profile/");

  useEffect(() => {
    for (const link of links) {
      router.prefetch(link.href);
    }
    router.prefetch("/app/settings");
    router.prefetch("/app/posts/new");
    router.prefetch("/app/clusters/new");
    router.prefetch("/app/settings/resources");
    router.prefetch("/app/settings/booking/inbox");
    router.prefetch("/app/settings/booking");
    router.prefetch("/app/settings/attendance");
    router.prefetch("/app/attendance");
  }, [router]);

  useEffect(() => {
    let cancelled = false;
    void createClient()
      .auth.getUser()
      .then(({ data }) => {
        if (cancelled) return;
        const id = data.user?.id ?? null;
        setUserId(id);
        setResourcesShortcut(id ? readResourcesShortcut(id) : false);
        setBookingShortcut(id ? readBookingShortcut(id) : false);
        setAttendanceShortcut(id ? readAttendanceShortcut(id) : false);
      });
    return () => {
      cancelled = true;
    };
  }, []);

  useEffect(() => {
    if (!userId) return;
    const syncResources = () => setResourcesShortcut(readResourcesShortcut(userId));
    const syncBooking = () => setBookingShortcut(readBookingShortcut(userId));
    const syncAttendance = () =>
      setAttendanceShortcut(readAttendanceShortcut(userId));
    const onResources = (e: Event) => {
      const detail = (e as CustomEvent<{ userId?: string }>).detail;
      if (!detail?.userId || detail.userId === userId) syncResources();
    };
    const onBooking = (e: Event) => {
      const detail = (e as CustomEvent<{ userId?: string }>).detail;
      if (!detail?.userId || detail.userId === userId) syncBooking();
    };
    const onAttendance = (e: Event) => {
      const detail = (e as CustomEvent<{ userId?: string }>).detail;
      if (!detail?.userId || detail.userId === userId) syncAttendance();
    };
    const onStorage = () => {
      syncResources();
      syncBooking();
      syncAttendance();
    };
    window.addEventListener(RESOURCES_SHORTCUT_EVENT, onResources);
    window.addEventListener(BOOKING_SHORTCUT_EVENT, onBooking);
    window.addEventListener(ATTENDANCE_SHORTCUT_EVENT, onAttendance);
    window.addEventListener("storage", onStorage);
    return () => {
      window.removeEventListener(RESOURCES_SHORTCUT_EVENT, onResources);
      window.removeEventListener(BOOKING_SHORTCUT_EVENT, onBooking);
      window.removeEventListener(ATTENDANCE_SHORTCUT_EVENT, onAttendance);
      window.removeEventListener("storage", onStorage);
    };
  }, [userId]);

  useEffect(() => {
    let cancelled = false;
    if (pathname.startsWith("/app/notifications")) {
      setUnread(0);
      return;
    }
    void countUnreadNotifications().then((n) => {
      if (!cancelled) setUnread(n);
    });
    return () => {
      cancelled = true;
    };
  }, [pathname]);

  return (
    <div
      className={`flex min-h-dvh flex-col md:flex-row ${
        mapFullBleed ? "bg-mint" : feedFullBleed ? "bg-bg" : "bg-bg"
      }`}
    >
      <aside
        className="group/rail fixed left-0 top-0 z-40 hidden h-dvh w-[4.5rem] flex-col border-r border-line bg-surface/95 py-4 backdrop-blur-md transition-[width] duration-200 ease-out hover:w-[15rem] hover:shadow-elevate-md md:flex"
        aria-label="Навигация"
      >
        <Link
          href="/app"
          prefetch
          className="mx-2 mb-6 flex h-12 items-center gap-3 overflow-hidden rounded-[14px] px-2.5 transition hover:bg-bg"
        >
          <Image
            src="/logo.png"
            alt=""
            width={36}
            height={36}
            priority
            className="h-9 w-9 shrink-0 object-contain"
          />
          <span className="min-w-0 truncate font-display text-[17px] font-semibold tracking-tight text-ink opacity-0 transition-opacity duration-200 group-hover/rail:opacity-100">
            {SITE.name}
          </span>
        </Link>

        <nav className="flex flex-1 flex-col gap-1 px-2">
          {links.map((link) => {
            const { href, label, match, Icon } = link;
            const active = match(pathname);
            const showBadge = "badge" in link && link.badge && unread > 0;
            return (
              <Link
                key={href}
                href={href}
                prefetch
                title={label}
                className={`flex h-12 items-center gap-4 overflow-hidden rounded-[14px] px-3 transition ${
                  active
                    ? "bg-mint text-brand"
                    : "text-nav-inactive hover:bg-surface-muted hover:text-ink"
                }`}
              >
                <span className="relative shrink-0">
                  <Icon
                    className="h-[26px] w-[26px]"
                    strokeWidth={active ? 2.25 : 1.75}
                  />
                  {showBadge ? (
                    <span className="absolute -right-1 -top-1 flex h-4 min-w-4 items-center justify-center rounded-full bg-brand px-1 text-[9px] font-bold text-on-brand">
                      {unread > 99 ? "99+" : unread}
                    </span>
                  ) : null}
                </span>
                <span
                  className={`truncate text-[15px] opacity-0 transition-opacity duration-200 group-hover/rail:opacity-100 ${
                    active ? "font-bold" : "font-semibold"
                  }`}
                >
                  {label}
                </span>
              </Link>
            );
          })}

          {resourcesShortcut ? (
            <Link
              href="/app/settings/resources"
              prefetch
              title="Ресурсы"
              className={`mt-2 flex h-12 items-center gap-4 overflow-hidden rounded-[14px] px-3 transition ${
                resourcesActive
                  ? "bg-svc-resources text-svc-resources-ink"
                  : "text-svc-resources-ink hover:bg-svc-resources/70"
              }`}
            >
              <Layers
                className="h-[26px] w-[26px] shrink-0"
                strokeWidth={resourcesActive ? 2.25 : 1.75}
              />
              <span
                className={`truncate text-[15px] opacity-0 transition-opacity duration-200 group-hover/rail:opacity-100 ${
                  resourcesActive ? "font-bold" : "font-semibold"
                }`}
              >
                Ресурсы
              </span>
            </Link>
          ) : null}

          {bookingShortcut ? (
            <Link
              href="/app/settings/booking/inbox"
              prefetch
              title="Мои записи"
              className={`mt-1 flex h-12 items-center gap-4 overflow-hidden rounded-[14px] px-3 transition ${
                bookingActive
                  ? "bg-svc-booking text-svc-booking-ink"
                  : "text-svc-booking-ink hover:bg-svc-booking/70"
              }`}
            >
              <CalendarDays
                className="h-[26px] w-[26px] shrink-0"
                strokeWidth={bookingActive ? 2.25 : 1.75}
              />
              <span
                className={`truncate text-[15px] opacity-0 transition-opacity duration-200 group-hover/rail:opacity-100 ${
                  bookingActive ? "font-bold" : "font-semibold"
                }`}
              >
                Запись
              </span>
            </Link>
          ) : null}

          {attendanceShortcut ? (
            <Link
              href="/app/attendance"
              prefetch
              title="Посещаемость"
              className={`mt-1 flex h-12 items-center gap-4 overflow-hidden rounded-[14px] px-3 transition ${
                attendanceActive
                  ? "bg-svc-attendance text-svc-attendance-ink"
                  : "text-svc-attendance-ink hover:bg-svc-attendance/70"
              }`}
            >
              <Building2
                className="h-[26px] w-[26px] shrink-0"
                strokeWidth={attendanceActive ? 2.25 : 1.75}
              />
              <span
                className={`truncate text-[15px] opacity-0 transition-opacity duration-200 group-hover/rail:opacity-100 ${
                  attendanceActive ? "font-bold" : "font-semibold"
                }`}
              >
                Посещаемость
              </span>
            </Link>
          ) : null}
        </nav>

        <div className="mt-auto space-y-1 px-2">
          <button
            type="button"
            title="Добавить"
            onClick={() => setAddOpen(true)}
            className={`flex h-12 w-full items-center gap-4 overflow-hidden rounded-[14px] px-3 transition ${
              createActive || addOpen
                ? "bg-mint text-brand"
                : "text-nav-inactive hover:bg-surface-muted hover:text-ink"
            }`}
          >
            <Plus
              className="h-[22px] w-[22px] shrink-0"
              strokeWidth={createActive || addOpen ? 2.5 : 2}
            />
            <span
              className={`truncate text-[15px] opacity-0 transition-opacity duration-200 group-hover/rail:opacity-100 ${
                createActive || addOpen ? "font-bold" : "font-semibold"
              }`}
            >
              Добавить
            </span>
          </button>
          <Link
            href="/app/settings"
            prefetch
            title="Настройки"
            className={`flex h-12 items-center gap-4 overflow-hidden rounded-[14px] px-3 transition ${
              settingsActive
                ? "bg-mint text-brand"
                : "text-nav-inactive hover:bg-surface-muted hover:text-ink"
            }`}
          >
            <Settings
              className="h-[22px] w-[22px] shrink-0"
              strokeWidth={settingsActive ? 2.25 : 1.75}
            />
            <span
              className={`truncate text-[15px] opacity-0 transition-opacity duration-200 group-hover/rail:opacity-100 ${
                settingsActive ? "font-bold" : "font-semibold"
              }`}
            >
              Настройки
            </span>
          </Link>
          <Link
            href="/"
            title="На сайт"
            className="flex h-12 items-center gap-4 overflow-hidden rounded-[14px] px-3 text-muted transition hover:bg-bg hover:text-ink"
          >
            <ExternalLink className="h-[22px] w-[22px] shrink-0" strokeWidth={1.75} />
            <span className="truncate text-[15px] font-semibold opacity-0 transition-opacity duration-200 group-hover/rail:opacity-100">
              На сайт
            </span>
          </Link>
        </div>
      </aside>

      <header className="sticky top-0 z-30 flex h-12 items-center justify-between border-b border-line bg-surface/95 px-4 backdrop-blur-md md:hidden">
        <Link href="/app" prefetch className="flex items-center gap-2">
          <Image
            src="/logo.png"
            alt=""
            width={28}
            height={28}
            className="h-7 w-7 object-contain"
          />
          <span className="font-display text-base font-semibold tracking-tight text-ink">
            {SITE.name}
          </span>
        </Link>
        <Link
          href="/app/notifications"
          prefetch
          title="Уведомления"
          className="relative flex h-9 w-9 items-center justify-center rounded-full text-ink hover:bg-bg"
        >
          <Bell className="h-5 w-5" strokeWidth={1.75} />
          {unread > 0 ? (
            <span className="absolute right-0.5 top-0.5 flex h-4 min-w-4 items-center justify-center rounded-full bg-brand px-1 text-[9px] font-bold text-on-brand">
              {unread > 99 ? "99+" : unread}
            </span>
          ) : null}
        </Link>
      </header>

      <main
        className={`min-w-0 flex-1 pb-[4.25rem] md:pb-0 md:pl-[4.5rem] ${
          mapFullBleed || feedFullBleed
            ? "w-full p-0"
            : "mx-auto w-full max-w-6xl px-4 py-6 sm:px-6 sm:py-8"
        }`}
      >
        {children}
      </main>

      <div className="fixed inset-x-0 bottom-0 z-40 md:hidden">
        {onOwnProfile &&
        (resourcesShortcut || bookingShortcut || attendanceShortcut) ? (
          <div className="pointer-events-none absolute bottom-[calc(4.25rem+env(safe-area-inset-bottom))] right-3 mb-2 flex flex-col items-end gap-2">
            {attendanceShortcut ? (
              <Link
                href="/app/attendance"
                prefetch
                title="Посещаемость"
                className={`pointer-events-auto inline-flex h-11 items-center gap-2 rounded-[14px] px-3.5 text-[13px] font-bold shadow-elevate-sm ${
                  attendanceActive
                    ? "bg-svc-attendance-ink text-on-media"
                    : "bg-svc-attendance text-svc-attendance-ink"
                }`}
              >
                <Building2 className="h-4 w-4" strokeWidth={2} />
                Посещаемость
              </Link>
            ) : null}
            {bookingShortcut ? (
              <Link
                href="/app/settings/booking/inbox"
                prefetch
                title="Мои записи"
                className={`pointer-events-auto inline-flex h-11 items-center gap-2 rounded-[14px] px-3.5 text-[13px] font-bold shadow-elevate-sm ${
                  bookingActive
                    ? "bg-svc-booking-ink text-on-media"
                    : "bg-svc-booking text-svc-booking-ink"
                }`}
              >
                <CalendarDays className="h-4 w-4" strokeWidth={2} />
                Запись
              </Link>
            ) : null}
            {resourcesShortcut ? (
              <Link
                href="/app/settings/resources"
                prefetch
                title="Ресурсы"
                className={`pointer-events-auto inline-flex h-11 items-center gap-2 rounded-[14px] px-3.5 text-[13px] font-bold shadow-elevate-sm ${
                  resourcesActive
                    ? "bg-svc-resources-ink text-on-media"
                    : "bg-svc-resources text-svc-resources-ink"
                }`}
              >
                <Layers className="h-4 w-4" strokeWidth={2} />
                Ресурсы
              </Link>
            ) : null}
          </div>
        ) : null}
        <nav
          className="flex h-[4.25rem] items-center justify-around border-t border-line bg-surface/95 px-2 pb-[env(safe-area-inset-bottom)] backdrop-blur-md"
          aria-label="Разделы"
        >
          {links
            .filter((l) => l.href !== "/app/notifications")
            .map((link) => {
              const { href, label, match, Icon } = link;
              const active = match(pathname);
              return (
                <Link
                  key={href}
                  href={href}
                  prefetch
                  className={`flex min-w-0 flex-1 flex-col items-center gap-0.5 rounded-[12px] px-1 py-1.5 ${
                    active ? "text-brand" : "text-nav-inactive"
                  }`}
                >
                  <Icon className="h-6 w-6" strokeWidth={active ? 2.25 : 1.75} />
                  <span className={`truncate text-[10px] ${active ? "font-bold" : "font-semibold"}`}>
                    {label}
                  </span>
                </Link>
              );
            })}
        </nav>
      </div>

      {addOpen ? (
        <div className="fixed inset-0 z-50 flex items-end justify-center sm:items-center">
          <button
            type="button"
            className="absolute inset-0 bg-ink/40"
            aria-label="Закрыть"
            onClick={() => setAddOpen(false)}
          />
          <div className="relative z-10 w-full max-w-md rounded-t-[20px] bg-surface shadow-elevate-lg sm:rounded-[20px]">
            <div className="border-b border-line px-4 py-3">
              <h2 className="text-[16px] font-bold text-ink">Добавить</h2>
            </div>
            <ul className="p-2">
              <li>
                <Link
                  href="/app/posts/new"
                  onClick={() => setAddOpen(false)}
                  className="flex items-center gap-3 rounded-[14px] px-3 py-3.5 hover:bg-bg"
                >
                  <span className="flex h-10 w-10 items-center justify-center rounded-[12px] bg-mint text-brand">
                    <Plus className="h-5 w-5" strokeWidth={2.5} />
                  </span>
                  <span>
                    <span className="block text-[15px] font-bold text-ink">Добавить пост</span>
                    <span className="block text-[12px] text-muted">Фото и публикация</span>
                  </span>
                </Link>
              </li>
              <li>
                <Link
                  href="/app/clusters/new"
                  onClick={() => setAddOpen(false)}
                  className="flex items-center gap-3 rounded-[14px] px-3 py-3.5 hover:bg-bg"
                >
                  <span className="flex h-10 w-10 items-center justify-center rounded-[12px] bg-mint text-brand">
                    <FolderPlus className="h-5 w-5" strokeWidth={2} />
                  </span>
                  <span>
                    <span className="block text-[15px] font-bold text-ink">Добавить кластер</span>
                    <span className="block text-[12px] text-muted">Коллекция на профиле</span>
                  </span>
                </Link>
              </li>
            </ul>
          </div>
        </div>
      ) : null}
    </div>
  );
}
