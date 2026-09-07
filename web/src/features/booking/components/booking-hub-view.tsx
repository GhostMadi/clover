"use client";

import {
  BarChart3,
  CalendarDays,
  ChevronRight,
  ClipboardList,
  Scissors,
  Settings2,
} from "lucide-react";
import Link from "next/link";
import { useEffect, useMemo, useState } from "react";
import { createClient } from "@/lib/supabase/client";
import { BookingWorkspaceShell } from "@/features/booking/components/booking-workspace-shell";
import { BookingListShimmer } from "@/features/booking/components/booking-shimmers";
import { listHostBookings } from "@/features/booking/lib/bookings-api";
import type { HostBookingItem } from "@/features/booking/lib/booking-model";
import {
  endsAt,
  formatBookingWhen,
  formatPriceKzt,
  hostInboxRange,
  statusLabelRu,
} from "@/features/booking/lib/booking-format";
import {
  readBookingShortcut,
  writeBookingShortcut,
} from "@/features/booking/lib/shortcut-prefs";

const TILES = [
  {
    href: "/app/settings/booking/inbox",
    label: "Мои записи",
    subtitle: "Inbox: визиты и статусы",
    icon: ClipboardList,
  },
  {
    href: "/app/settings/booking/services",
    label: "Услуги",
    subtitle: "Каталог, мастера, бонусы",
    icon: Scissors,
  },
  {
    href: "/app/settings/booking/schedule",
    label: "Расписание",
    subtitle: "Часы, отсутствия, блокировки",
    icon: Settings2,
  },
  {
    href: "/app/settings/booking/analytics",
    label: "Аналитика",
    subtitle: "Сводка за период",
    icon: BarChart3,
  },
  {
    href: "/app/settings/booking/my",
    label: "Мои бронирования",
    subtitle: "Где вы клиент",
    icon: CalendarDays,
  },
] as const;

function isInChair(b: HostBookingItem, now: number): boolean {
  if (b.status === "client_arrived" || b.status === "in_progress") return true;
  if (b.status !== "confirmed") return false;
  const start = new Date(b.startsAt).getTime();
  const end = endsAt(b.startsAt, b.durationMinutes).getTime();
  return start <= now && now < end;
}

function isUpcoming(b: HostBookingItem, now: number): boolean {
  return (
    new Date(b.startsAt).getTime() > now &&
    (b.status === "confirmed" || b.status === "pending")
  );
}

export function BookingHubView() {
  const [uid, setUid] = useState<string | null>(null);
  const [shortcut, setShortcut] = useState(false);
  const [items, setItems] = useState<HostBookingItem[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    void createClient()
      .auth.getSession()
      .then(({ data }) => {
        const id = data.session?.user.id ?? null;
        setUid(id);
        if (id) setShortcut(readBookingShortcut(id));
      });
  }, []);

  useEffect(() => {
    let cancelled = false;
    const { from, to } = hostInboxRange();
    void listHostBookings({ from, to })
      .then((list) => {
        if (!cancelled) setItems(list);
      })
      .catch(() => {
        if (!cancelled) setItems([]);
      })
      .finally(() => {
        if (!cancelled) setLoading(false);
      });
    return () => {
      cancelled = true;
    };
  }, []);

  const now = Date.now();
  const inChair = useMemo(
    () => items.filter((b) => isInChair(b, now)),
    [items, now],
  );
  const upcoming = useMemo(
    () =>
      items
        .filter((b) => isUpcoming(b, now))
        .sort((a, b) => +new Date(a.startsAt) - +new Date(b.startsAt))
        .slice(0, 5),
    [items, now],
  );

  return (
    <BookingWorkspaceShell
      title="Обзор"
      trailing={
        <label className="flex items-center gap-2 text-[12px] font-semibold text-muted">
          <span className="hidden sm:inline">Кнопка сбоку</span>
          <button
            type="button"
            role="switch"
            aria-checked={shortcut}
            disabled={!uid}
            onClick={() => {
              if (!uid) return;
              const next = !shortcut;
              setShortcut(next);
              writeBookingShortcut(uid, next);
            }}
            className={`relative h-7 w-12 shrink-0 rounded-full transition ${
              shortcut ? "bg-svc-booking" : "bg-line"
            } disabled:opacity-40`}
          >
            <span
              className={`absolute top-0.5 h-6 w-6 rounded-full bg-surface shadow-elevate-sm transition ${
                shortcut ? "left-[1.35rem]" : "left-0.5"
              }`}
            />
          </button>
        </label>
      }
    >
      <div className="space-y-6">
        <section>
          <p className="mb-3 text-[12px] font-bold uppercase tracking-wide text-muted">
            Разделы
          </p>
          <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
            {TILES.map((item) => {
              const Icon = item.icon;
              return (
                <Link
                  key={item.href}
                  href={item.href}
                  className="group flex items-start gap-3 rounded-[16px] border border-line bg-surface p-4 transition hover:border-svc-booking-ink/30 hover:bg-svc-booking/35"
                >
                  <span className="flex h-11 w-11 shrink-0 items-center justify-center rounded-[12px] bg-svc-booking text-svc-booking-ink">
                    <Icon className="h-5 w-5" strokeWidth={2} />
                  </span>
                  <span className="min-w-0 flex-1">
                    <span className="flex items-center gap-1 text-[15px] font-bold text-ink">
                      {item.label}
                      <ChevronRight className="h-4 w-4 text-muted opacity-0 transition group-hover:opacity-100" />
                    </span>
                    <span className="mt-0.5 block text-[12px] text-muted">{item.subtitle}</span>
                  </span>
                </Link>
              );
            })}
          </div>
        </section>

        <section className="grid gap-4 lg:grid-cols-2">
          <div className="rounded-[16px] border border-line bg-surface p-4">
            <div className="mb-3 flex items-center justify-between gap-2">
              <h2 className="text-[14px] font-bold text-ink">Сейчас в кресле</h2>
              <Link
                href="/app/settings/booking/inbox"
                className="text-[12px] font-bold text-svc-booking-ink hover:underline"
              >
                Весь inbox
              </Link>
            </div>
            {loading ? (
              <BookingListShimmer rows={2} />
            ) : inChair.length === 0 ? (
              <p className="text-[13px] text-muted">Нет активного визита</p>
            ) : (
              <ul className="space-y-2">
                {inChair.map((item) => (
                  <li key={item.id}>
                    <Link
                      href={`/app/settings/booking/inbox/${item.id}`}
                      className="block rounded-[12px] bg-svc-booking/50 px-3 py-2.5 transition hover:bg-svc-booking"
                    >
                      <p className="text-[14px] font-bold text-ink">
                        {item.serviceEmoji} {item.serviceTitle}
                      </p>
                      <p className="text-[12px] text-muted">
                        {item.clientName} · {statusLabelRu(item.status)}
                      </p>
                    </Link>
                  </li>
                ))}
              </ul>
            )}
          </div>

          <div className="rounded-[16px] border border-line bg-surface p-4">
            <div className="mb-3 flex items-center justify-between gap-2">
              <h2 className="text-[14px] font-bold text-ink">Ближайшие</h2>
              <span className="text-[11px] text-muted">{upcoming.length} из окна</span>
            </div>
            {loading ? (
              <BookingListShimmer rows={3} />
            ) : upcoming.length === 0 ? (
              <p className="text-[13px] text-muted">Нет предстоящих записей</p>
            ) : (
              <ul className="divide-y divide-line">
                {upcoming.map((item) => (
                  <li key={item.id}>
                    <Link
                      href={`/app/settings/booking/inbox/${item.id}`}
                      className="flex items-start justify-between gap-3 py-2.5 transition hover:bg-svc-booking/25"
                    >
                      <div className="min-w-0">
                        <p className="truncate text-[14px] font-semibold text-ink">
                          {item.serviceEmoji} {item.serviceTitle}
                        </p>
                        <p className="truncate text-[12px] text-muted">{item.clientName}</p>
                      </div>
                      <div className="shrink-0 text-right">
                        <p className="text-[12px] font-bold text-ink">
                          {formatBookingWhen(item.startsAt)}
                        </p>
                        <p className="text-[11px] text-muted">{formatPriceKzt(item.price)}</p>
                      </div>
                    </Link>
                  </li>
                ))}
              </ul>
            )}
          </div>
        </section>
      </div>
    </BookingWorkspaceShell>
  );
}
