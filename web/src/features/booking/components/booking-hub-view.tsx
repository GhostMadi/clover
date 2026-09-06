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
import { useEffect, useState } from "react";
import { createClient } from "@/lib/supabase/client";
import { serviceTileIcon } from "@/lib/service-accent";
import { SettingsShell } from "@/features/settings/components/settings-shell";
import {
  readBookingShortcut,
  writeBookingShortcut,
} from "@/features/booking/lib/shortcut-prefs";

const LINKS = [
  {
    href: "/app/settings/booking/inbox",
    label: "Мои записи",
    subtitle: "Inbox хозяина: визиты и статусы",
    icon: ClipboardList,
  },
  {
    href: "/app/settings/booking/services",
    label: "Услуги",
    subtitle: "Каталог, мастера и бонусы на услуге",
    icon: Scissors,
  },
  {
    href: "/app/settings/booking/schedule",
    label: "Расписание",
    subtitle: "Горизонт, часы, отсутствия, блокировки",
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
    subtitle: "Записи, где вы клиент",
    icon: CalendarDays,
  },
] as const;

export function BookingHubView() {
  const [uid, setUid] = useState<string | null>(null);
  const [shortcut, setShortcut] = useState(false);

  useEffect(() => {
    void createClient()
      .auth.getSession()
      .then(({ data }) => {
        const id = data.session?.user.id ?? null;
        setUid(id);
        if (id) setShortcut(readBookingShortcut(id));
      });
  }, []);

  return (
    <SettingsShell title="Запись" service="booking">
      <div className="space-y-6 px-4 py-5">
        <section>
          <p className="mb-2 px-1 text-[12px] font-bold uppercase tracking-wide text-muted">
            Навигация
          </p>
          <div className="rounded-[16px] border border-line bg-surface px-3.5 py-3.5">
            <div className="flex items-start justify-between gap-3">
              <div className="min-w-0 flex-1">
                <p className="text-[15px] font-bold text-ink">Кнопка «Запись» сбоку</p>
                <p className="mt-0.5 text-[12px] text-muted">
                  Открывает «Мои записи»; назад — в хаб «Запись»
                </p>
              </div>
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
            </div>
          </div>
        </section>

        <section>
          <p className="mb-2 px-1 text-[12px] font-bold uppercase tracking-wide text-muted">
            Разделы
          </p>
          <ul className="overflow-hidden rounded-[16px] border border-line bg-surface">
            {LINKS.map((item, i) => {
              const Icon = item.icon;
              return (
                <li key={item.href} className={i > 0 ? "border-t border-line" : ""}>
                  <Link
                    href={item.href}
                    className="flex items-center gap-3 px-3.5 py-3.5 transition hover:bg-svc-booking/40"
                  >
                    <span className={serviceTileIcon("booking")}>
                      <Icon className="h-5 w-5" strokeWidth={2} />
                    </span>
                    <span className="min-w-0 flex-1">
                      <span className="block text-[15px] font-bold text-ink">{item.label}</span>
                      <span className="block text-[12px] text-muted">{item.subtitle}</span>
                    </span>
                    <ChevronRight className="h-5 w-5 text-muted" strokeWidth={2} />
                  </Link>
                </li>
              );
            })}
          </ul>
        </section>
      </div>
    </SettingsShell>
  );
}
