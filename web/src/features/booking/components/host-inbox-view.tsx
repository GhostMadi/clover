"use client";

import { ChevronLeft, ChevronRight } from "lucide-react";
import Link from "next/link";
import { useEffect, useMemo, useState } from "react";
import { BookingWorkspaceShell } from "@/features/booking/components/booking-workspace-shell";
import { BookingListShimmer } from "@/features/booking/components/booking-shimmers";
import { listHostBookings } from "@/features/booking/lib/bookings-api";
import type { HostBookingItem } from "@/features/booking/lib/booking-model";
import {
  addDays,
  dateKeyLocal,
  endsAt,
  formatPriceKzt,
  formatSlotTime,
  hostInboxRange,
  startOfLocalDay,
  statusLabelRu,
} from "@/features/booking/lib/booking-format";

type Tab = "calendar" | "now" | "archive";

const WEEKDAYS = ["пн", "вт", "ср", "чт", "пт", "сб", "вс"] as const;

function isInChair(b: HostBookingItem, now: number): boolean {
  if (b.status === "client_arrived" || b.status === "in_progress") return true;
  if (b.status !== "confirmed") return false;
  const start = new Date(b.startsAt).getTime();
  const end = endsAt(b.startsAt, b.durationMinutes).getTime();
  return start <= now && now < end;
}

function isActiveUpcoming(b: HostBookingItem, now: number): boolean {
  return (
    new Date(b.startsAt).getTime() > now &&
    (b.status === "confirmed" || b.status === "pending")
  );
}

/** Понедельник = 0 … воскресенье = 6 */
function mondayIndex(d: Date): number {
  return (d.getDay() + 6) % 7;
}

function monthLabel(d: Date): string {
  return d.toLocaleDateString("ru-RU", { month: "long", year: "numeric" });
}

function dayTitle(key: string): string {
  return new Date(`${key}T12:00:00`).toLocaleDateString("ru-RU", {
    weekday: "long",
    day: "numeric",
    month: "long",
  });
}

export function HostInboxView() {
  const todayKey = dateKeyLocal(startOfLocalDay());
  const [items, setItems] = useState<HostBookingItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [query, setQuery] = useState("");
  const [tab, setTab] = useState<Tab>("calendar");
  const [cursorMonth, setCursorMonth] = useState(
    () => new Date(startOfLocalDay().getFullYear(), startOfLocalDay().getMonth(), 1),
  );
  const [selectedDay, setSelectedDay] = useState<string | null>(todayKey);

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

  const countsByDay = useMemo(() => {
    const map = new Map<string, number>();
    for (const b of items) {
      if (b.status === "cancelled") continue;
      const key = dateKeyLocal(new Date(b.startsAt));
      map.set(key, (map.get(key) ?? 0) + 1);
    }
    return map;
  }, [items]);

  const inChair = useMemo(
    () => items.filter((b) => isInChair(b, now)),
    [items, now],
  );

  const archive = useMemo(
    () =>
      items
        .filter((b) => !isInChair(b, now) && !isActiveUpcoming(b, now))
        .sort((a, b) => +new Date(b.startsAt) - +new Date(a.startsAt)),
    [items, now],
  );

  const dayBookings = useMemo(() => {
    if (!selectedDay) return [];
    return items
      .filter((b) => dateKeyLocal(new Date(b.startsAt)) === selectedDay)
      .sort((a, b) => +new Date(a.startsAt) - +new Date(b.startsAt));
  }, [items, selectedDay]);

  const calendarCells = useMemo(() => {
    const year = cursorMonth.getFullYear();
    const month = cursorMonth.getMonth();
    const first = new Date(year, month, 1);
    const startPad = mondayIndex(first);
    const daysInMonth = new Date(year, month + 1, 0).getDate();
    const cells: Array<{ key: string; day: number; inMonth: boolean } | null> =
      [];
    for (let i = 0; i < startPad; i++) cells.push(null);
    for (let d = 1; d <= daysInMonth; d++) {
      const date = new Date(year, month, d);
      cells.push({ key: dateKeyLocal(date), day: d, inMonth: true });
    }
    while (cells.length % 7 !== 0) cells.push(null);
    return cells;
  }, [cursorMonth]);

  const shiftMonth = (delta: number) => {
    setCursorMonth(
      (m) => new Date(m.getFullYear(), m.getMonth() + delta, 1),
    );
  };

  const goToday = () => {
    const t = startOfLocalDay();
    setCursorMonth(new Date(t.getFullYear(), t.getMonth(), 1));
    setSelectedDay(todayKey);
    setTab("calendar");
  };

  return (
    <BookingWorkspaceShell title="Мои записи">
      <div className="space-y-4">
        <div className="flex flex-col gap-3 lg:flex-row lg:items-center lg:justify-between">
          <input
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            placeholder="Поиск клиента или услуги"
            className="h-11 w-full rounded-[14px] border border-line bg-bg px-3.5 text-[14px] text-ink outline-none placeholder:text-muted focus:border-svc-booking-ink/50 lg:max-w-sm"
          />
          <div className="flex flex-wrap items-center gap-2">
            <button
              type="button"
              onClick={goToday}
              className="h-9 rounded-[10px] border border-line px-3 text-[12px] font-bold text-ink transition hover:bg-svc-booking/40"
            >
              Сегодня
            </button>
            <div className="flex gap-1 rounded-[14px] border border-line bg-surface p-1">
              {(
                [
                  ["calendar", "Календарь"],
                  ["now", "Сейчас"],
                  ["archive", "Архив"],
                ] as const
              ).map(([id, label]) => (
                <button
                  key={id}
                  type="button"
                  onClick={() => setTab(id)}
                  className={`rounded-[10px] px-3 py-2 text-[12px] font-bold transition ${
                    tab === id ? "bg-svc-booking text-svc-booking-ink" : "text-muted"
                  }`}
                >
                  {label}
                  {id === "now" && inChair.length > 0 ? (
                    <span className="ml-1 text-[10px]">({inChair.length})</span>
                  ) : null}
                </button>
              ))}
            </div>
          </div>
        </div>

        {error ? <p className="text-sm text-destructive">{error}</p> : null}

        {loading ? (
          <BookingListShimmer rows={8} />
        ) : tab === "now" ? (
          <NowList items={inChair} />
        ) : tab === "archive" ? (
          <AgendaList items={archive} empty="В архиве пока пусто." />
        ) : (
          <div className="grid gap-4 lg:grid-cols-[minmax(280px,380px)_1fr] lg:items-start">
            {/* Month calendar */}
            <section className="rounded-[16px] border border-line bg-surface p-3 sm:p-4">
              <div className="mb-3 flex items-center justify-between gap-2">
                <button
                  type="button"
                  onClick={() => shiftMonth(-1)}
                  className="flex h-9 w-9 items-center justify-center rounded-full text-svc-booking-ink transition hover:bg-svc-booking"
                  aria-label="Предыдущий месяц"
                >
                  <ChevronLeft className="h-5 w-5" strokeWidth={2} />
                </button>
                <h2 className="font-display text-[15px] font-semibold capitalize text-ink">
                  {monthLabel(cursorMonth)}
                </h2>
                <button
                  type="button"
                  onClick={() => shiftMonth(1)}
                  className="flex h-9 w-9 items-center justify-center rounded-full text-svc-booking-ink transition hover:bg-svc-booking"
                  aria-label="Следующий месяц"
                >
                  <ChevronRight className="h-5 w-5" strokeWidth={2} />
                </button>
              </div>

              <div className="mb-1 grid grid-cols-7 gap-0.5">
                {WEEKDAYS.map((w) => (
                  <div
                    key={w}
                    className="py-1 text-center text-[10px] font-bold uppercase tracking-wide text-muted"
                  >
                    {w}
                  </div>
                ))}
              </div>
              <div className="grid grid-cols-7 gap-0.5">
                {calendarCells.map((cell, i) => {
                  if (!cell) {
                    return <div key={`pad-${i}`} className="aspect-square" />;
                  }
                  const count = countsByDay.get(cell.key) ?? 0;
                  const selected = selectedDay === cell.key;
                  const isToday = cell.key === todayKey;
                  return (
                    <button
                      key={cell.key}
                      type="button"
                      onClick={() => setSelectedDay(cell.key)}
                      className={`relative flex aspect-square flex-col items-center justify-center rounded-[12px] text-[13px] font-semibold transition ${
                        selected
                          ? "bg-svc-booking-ink text-on-media"
                          : isToday
                            ? "bg-svc-booking text-svc-booking-ink"
                            : "text-ink hover:bg-svc-booking/40"
                      }`}
                    >
                      {cell.day}
                      {count > 0 ? (
                        <span
                          className={`mt-0.5 flex gap-0.5 ${
                            selected ? "opacity-90" : ""
                          }`}
                        >
                          {Array.from({ length: Math.min(count, 3) }).map((_, di) => (
                            <span
                              key={di}
                              className={`h-1 w-1 rounded-full ${
                                selected ? "bg-on-media" : "bg-svc-booking-ink"
                              }`}
                            />
                          ))}
                        </span>
                      ) : (
                        <span className="mt-0.5 h-1" />
                      )}
                    </button>
                  );
                })}
              </div>
              <p className="mt-3 text-[11px] text-muted">
                Точки — дни с записями · всего в окне {items.length}
              </p>
            </section>

            {/* Day agenda */}
            <section className="min-w-0 rounded-[16px] border border-line bg-surface p-3 sm:p-4">
              <div className="mb-3 flex flex-wrap items-end justify-between gap-2">
                <div>
                  <p className="text-[11px] font-bold uppercase tracking-wide text-muted">
                    День
                  </p>
                  <h2 className="font-display text-[17px] font-semibold capitalize text-ink">
                    {selectedDay ? dayTitle(selectedDay) : "Выберите день"}
                  </h2>
                </div>
                {selectedDay && selectedDay !== todayKey ? (
                  <button
                    type="button"
                    onClick={() => setSelectedDay(todayKey)}
                    className="text-[12px] font-bold text-svc-booking-ink hover:underline"
                  >
                    К сегодня
                  </button>
                ) : null}
              </div>

              {inChair.length > 0 && selectedDay === todayKey ? (
                <div className="mb-3 space-y-2">
                  <p className="text-[11px] font-bold uppercase tracking-wide text-svc-booking-ink">
                    Сейчас в кресле
                  </p>
                  {inChair.map((item) => (
                    <BookingRow key={item.id} item={item} highlight />
                  ))}
                </div>
              ) : null}

              {dayBookings.length === 0 ? (
                <p className="py-10 text-center text-[13px] text-muted">
                  На этот день записей нет.
                  {selectedDay === todayKey ? (
                    <>
                      {" "}
                      <button
                        type="button"
                        className="font-bold text-svc-booking-ink hover:underline"
                        onClick={() => {
                          const next = addDays(startOfLocalDay(), 1);
                          setSelectedDay(dateKeyLocal(next));
                          setCursorMonth(
                            new Date(next.getFullYear(), next.getMonth(), 1),
                          );
                        }}
                      >
                        Смотреть завтра
                      </button>
                    </>
                  ) : null}
                </p>
              ) : (
                <ul className="space-y-2">
                  {dayBookings.map((item) => (
                    <li key={item.id}>
                      <BookingRow item={item} />
                    </li>
                  ))}
                </ul>
              )}
            </section>
          </div>
        )}
      </div>
    </BookingWorkspaceShell>
  );
}

function NowList({ items }: { items: HostBookingItem[] }) {
  if (items.length === 0) {
    return <p className="text-sm text-muted">Сейчас никто не в кресле.</p>;
  }
  return (
    <ul className="space-y-2">
      {items.map((item) => (
        <li key={item.id}>
          <BookingRow item={item} highlight />
        </li>
      ))}
    </ul>
  );
}

function AgendaList({
  items,
  empty,
}: {
  items: HostBookingItem[];
  empty: string;
}) {
  if (items.length === 0) {
    return <p className="text-sm text-muted">{empty}</p>;
  }
  return (
    <ul className="space-y-2">
      {items.map((item) => (
        <li key={item.id}>
          <BookingRow item={item} showDate />
        </li>
      ))}
    </ul>
  );
}

function BookingRow({
  item,
  highlight,
  showDate,
}: {
  item: HostBookingItem;
  highlight?: boolean;
  showDate?: boolean;
}) {
  return (
    <Link
      href={`/app/settings/booking/inbox/${item.id}`}
      className={`flex gap-3 rounded-[14px] border px-3 py-3 transition ${
        highlight
          ? "border-svc-booking-ink/25 bg-svc-booking"
          : "border-line bg-bg hover:bg-svc-booking/30"
      }`}
    >
      <div className="w-14 shrink-0 text-center">
        <p className="text-[15px] font-extrabold text-ink">
          {formatSlotTime(item.startsAt)}
        </p>
        {showDate ? (
          <p className="mt-0.5 text-[10px] font-semibold text-muted">
            {new Date(item.startsAt).toLocaleDateString("ru-RU", {
              day: "numeric",
              month: "short",
            })}
          </p>
        ) : (
          <p className="mt-0.5 text-[10px] font-semibold text-muted">
            {item.durationMinutes} мин
          </p>
        )}
      </div>
      <div className="min-w-0 flex-1 border-l border-line pl-3">
        <p className="truncate text-[14px] font-bold text-ink">
          {item.serviceEmoji} {item.serviceTitle}
        </p>
        <p className="truncate text-[12px] text-muted">
          {item.clientName}
          {item.clientUsername ? ` · @${item.clientUsername}` : ""}
          {item.executorName ? ` · ${item.executorName}` : ""}
        </p>
        <div className="mt-1.5 flex flex-wrap items-center gap-2">
          <span className="rounded-full bg-svc-booking px-2 py-0.5 text-[10px] font-bold text-svc-booking-ink">
            {statusLabelRu(item.status)}
          </span>
          <span className="text-[11px] font-semibold text-muted">
            {formatPriceKzt(item.price)}
          </span>
        </div>
      </div>
    </Link>
  );
}
