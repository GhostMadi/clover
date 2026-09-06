"use client";

import { useEffect, useMemo, useState } from "react";
import Link from "next/link";
import { SettingsShell } from "@/features/settings/components/settings-shell";
import { BookingListShimmer } from "@/features/booking/components/booking-shimmers";
import { listHostBookings } from "@/features/booking/lib/bookings-api";
import type { HostBookingItem } from "@/features/booking/lib/booking-model";
import {
  dateKeyLocal,
  endsAt,
  formatBookingWhen,
  formatPriceKzt,
  hostInboxRange,
  startOfLocalDay,
  statusLabelRu,
} from "@/features/booking/lib/booking-format";

type Tab = "now" | "upcoming" | "archive";

export function HostInboxView() {
  const [items, setItems] = useState<HostBookingItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [query, setQuery] = useState("");
  const [tab, setTab] = useState<Tab>("upcoming");
  const [dayFilter, setDayFilter] = useState<string | null>(null);

  useEffect(() => {
    let cancelled = false;
    const t = setTimeout(() => {
      setLoading(true);
      const { from, to } = hostInboxRange();
      void listHostBookings({
        from,
        to,
        query: query.trim().length >= 2 ? query.trim() : undefined,
      })
        .then((list) => {
          if (!cancelled) setItems(list);
        })
        .catch((e: unknown) => {
          if (!cancelled) setError(e instanceof Error ? e.message : "Ошибка");
        })
        .finally(() => {
          if (!cancelled) setLoading(false);
        });
    }, query.trim().length >= 2 ? 300 : 0);
    return () => {
      cancelled = true;
      clearTimeout(t);
    };
  }, [query]);

  const now = Date.now();

  const filtered = useMemo(() => {
    const inChair = (b: HostBookingItem) => {
      if (b.status === "client_arrived" || b.status === "in_progress") return true;
      if (b.status !== "confirmed") return false;
      const start = new Date(b.startsAt).getTime();
      const end = endsAt(b.startsAt, b.durationMinutes).getTime();
      return start <= now && now < end;
    };
    const upcoming = (b: HostBookingItem) => {
      const start = new Date(b.startsAt).getTime();
      return start > now && (b.status === "confirmed" || b.status === "pending");
    };
    const archive = (b: HostBookingItem) => !inChair(b) && !upcoming(b);

    let list =
      tab === "now"
        ? items.filter(inChair)
        : tab === "upcoming"
          ? items.filter(upcoming)
          : items.filter(archive);

    if (tab === "upcoming" && dayFilter) {
      list = list.filter((b) => dateKeyLocal(new Date(b.startsAt)) === dayFilter);
    }
    return list;
  }, [items, tab, dayFilter, now]);

  const dayKeys = useMemo(() => {
    const set = new Set<string>();
    for (const b of items) {
      if (
        new Date(b.startsAt).getTime() > now &&
        (b.status === "confirmed" || b.status === "pending")
      ) {
        set.add(dateKeyLocal(new Date(b.startsAt)));
      }
    }
    return [...set].sort();
  }, [items, now]);

  return (
    <SettingsShell title="Мои записи" backHref="/app/settings/booking" service="booking">
      <div className="space-y-4 px-4 py-4">
        <input
          value={query}
          onChange={(e) => setQuery(e.target.value)}
          placeholder="Поиск (от 2 символов)"
          className="h-11 w-full rounded-[14px] border border-line bg-bg px-3.5 text-[14px] text-ink outline-none placeholder:text-muted focus:border-svc-booking-ink/50"
        />

        <div className="flex gap-1 rounded-[14px] border border-line bg-surface p-1">
          {(
            [
              ["now", "Сейчас"],
              ["upcoming", "Предстоящие"],
              ["archive", "Архив"],
            ] as const
          ).map(([id, label]) => (
            <button
              key={id}
              type="button"
              onClick={() => setTab(id)}
              className={`flex-1 rounded-[10px] py-2 text-[12px] font-bold transition ${
                tab === id ? "bg-svc-booking text-svc-booking-ink" : "text-muted"
              }`}
            >
              {label}
            </button>
          ))}
        </div>

        {tab === "upcoming" && dayKeys.length > 0 ? (
          <div className="flex gap-2 overflow-x-auto pb-1">
            <button
              type="button"
              onClick={() => setDayFilter(null)}
              className={`shrink-0 rounded-full px-3 py-1.5 text-[12px] font-semibold ${
                !dayFilter ? "bg-svc-booking-ink text-on-media" : "border border-line"
              }`}
            >
              Все
            </button>
            {dayKeys.map((k) => (
              <button
                key={k}
                type="button"
                onClick={() => setDayFilter(k)}
                className={`shrink-0 rounded-full px-3 py-1.5 text-[12px] font-semibold ${
                  dayFilter === k ? "bg-svc-booking-ink text-on-media" : "border border-line"
                }`}
              >
                {new Date(`${k}T12:00:00`).toLocaleDateString("ru-RU", {
                  day: "numeric",
                  month: "short",
                })}
              </button>
            ))}
          </div>
        ) : null}

        {error ? <p className="text-sm text-destructive">{error}</p> : null}
        {loading ? (
          <BookingListShimmer rows={6} />
        ) : filtered.length === 0 ? (
          <p className="text-sm text-muted">Нет записей в этой вкладке.</p>
        ) : (
          <ul className="space-y-2">
            {filtered.map((item) => (
              <li key={item.id}>
                <Link
                  href={`/app/settings/booking/inbox/${item.id}`}
                  className="block rounded-[16px] border border-line bg-surface px-3.5 py-3 transition hover:bg-svc-booking/30"
                >
                  <div className="flex items-start justify-between gap-2">
                    <div className="min-w-0">
                      <p className="text-[15px] font-bold text-ink">
                        {item.serviceEmoji} {item.serviceTitle}
                      </p>
                      <p className="mt-0.5 text-[13px] text-muted">
                        {item.clientName}
                        {item.clientUsername ? ` · @${item.clientUsername}` : ""}
                      </p>
                      <p className="mt-1 text-[13px] font-semibold text-ink">
                        {formatBookingWhen(item.startsAt)} · {formatPriceKzt(item.price)}
                      </p>
                    </div>
                    <span className="shrink-0 text-[11px] font-bold text-svc-booking-ink">
                      {statusLabelRu(item.status)}
                    </span>
                  </div>
                </Link>
              </li>
            ))}
          </ul>
        )}
        <p className="text-[11px] text-muted">
          Сегодня {dateKeyLocal(startOfLocalDay())} · всего в окне {items.length}
        </p>
      </div>
    </SettingsShell>
  );
}
