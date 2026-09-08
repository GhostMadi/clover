"use client";

import { ChevronLeft, UserRound } from "lucide-react";
import { useEffect, useState } from "react";
import { BookingWorkspaceShell } from "@/features/booking/components/booking-workspace-shell";
import { BookingListShimmer } from "@/features/booking/components/booking-shimmers";
import {
  listCalendarBookings,
  listCalendarHosts,
  type BookingCalendarHost,
  type BookingCalendarItem,
} from "@/features/booking/lib/calendar-api";
import {
  formatBookingWhen,
  formatPriceKzt,
  hostInboxRange,
  statusLabelRu,
} from "@/features/booking/lib/booking-format";

/** Календарь заказов, где текущий пользователь — исполнитель (read-only). */
export function BookingCalendarView() {
  const [hosts, setHosts] = useState<BookingCalendarHost[]>([]);
  const [hostsLoading, setHostsLoading] = useState(true);
  const [selectedHostId, setSelectedHostId] = useState<string | null>(null);
  const [items, setItems] = useState<BookingCalendarItem[]>([]);
  const [itemsLoading, setItemsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let cancelled = false;
    setHostsLoading(true);
    void listCalendarHosts()
      .then((list) => {
        if (!cancelled) setHosts(list);
      })
      .catch((e: unknown) => {
        if (!cancelled) {
          setError(e instanceof Error ? e.message : "Не удалось загрузить источники");
          setHosts([]);
        }
      })
      .finally(() => {
        if (!cancelled) setHostsLoading(false);
      });
    return () => {
      cancelled = true;
    };
  }, []);

  useEffect(() => {
    if (!selectedHostId) {
      setItems([]);
      return;
    }
    let cancelled = false;
    setItemsLoading(true);
    setError(null);
    const { from, to } = hostInboxRange();
    void listCalendarBookings({ from, to, hostId: selectedHostId })
      .then((list) => {
        if (!cancelled) setItems(list);
      })
      .catch((e: unknown) => {
        if (!cancelled) {
          setError(e instanceof Error ? e.message : "Не удалось загрузить записи");
          setItems([]);
        }
      })
      .finally(() => {
        if (!cancelled) setItemsLoading(false);
      });
    return () => {
      cancelled = true;
    };
  }, [selectedHostId]);

  const selectedHost = hosts.find((h) => h.hostId === selectedHostId) ?? null;

  return (
    <BookingWorkspaceShell
      title={selectedHost ? selectedHost.hostDisplayName || "Календарь" : "Календарь"}
      backHref="/app/settings"
      hideNav
      trailing={
        selectedHostId ? (
          <button
            type="button"
            onClick={() => setSelectedHostId(null)}
            className="flex items-center gap-1 rounded-[12px] px-2 py-1.5 text-[13px] font-bold text-svc-booking-ink hover:bg-svc-booking/40"
          >
            <ChevronLeft className="h-4 w-4" strokeWidth={2.5} />
            Источники
          </button>
        ) : null
      }
    >
      <div className="space-y-4">
        {error ? <p className="text-sm text-destructive">{error}</p> : null}

        {!selectedHostId ? (
          <>
            <p className="text-[13px] text-muted">
              Точки, где вы исполнитель. Выберите источник, чтобы увидеть свои визиты.
            </p>
            {hostsLoading ? (
              <BookingListShimmer rows={4} />
            ) : hosts.length === 0 ? (
              <p className="rounded-[14px] border border-dashed border-line bg-surface px-4 py-8 text-center text-sm text-muted">
                Пока нет привязок к хозяевам записи
              </p>
            ) : (
              <ul className="space-y-2">
                {hosts.map((host) => {
                  const nick = host.hostUsername?.trim();
                  return (
                    <li key={`${host.hostId}-${host.staffId}`}>
                      <button
                        type="button"
                        onClick={() => setSelectedHostId(host.hostId)}
                        className="flex w-full items-center gap-3 rounded-[16px] border border-line bg-surface px-3.5 py-3 text-left transition hover:border-svc-booking-ink/30 hover:bg-svc-booking/30"
                      >
                        <span className="flex h-11 w-11 shrink-0 items-center justify-center rounded-full bg-svc-booking text-svc-booking-ink">
                          <UserRound className="h-5 w-5" strokeWidth={2} />
                        </span>
                        <span className="min-w-0 flex-1">
                          <span className="block truncate text-[15px] font-bold text-ink">
                            {host.hostDisplayName || "Хозяин"}
                          </span>
                          {nick ? (
                            <span className="block truncate text-[12px] text-muted">
                              {nick.startsWith("@") ? nick : `@${nick}`}
                            </span>
                          ) : null}
                          {!host.isActive ? (
                            <span className="mt-0.5 block text-[11px] font-medium text-muted">
                              неактивен
                            </span>
                          ) : null}
                        </span>
                      </button>
                    </li>
                  );
                })}
              </ul>
            )}
          </>
        ) : itemsLoading ? (
          <BookingListShimmer rows={5} />
        ) : items.length === 0 ? (
          <p className="rounded-[14px] border border-dashed border-line bg-surface px-4 py-8 text-center text-sm text-muted">
            Нет визитов в этом окне
          </p>
        ) : (
          <ul className="space-y-2">
            {items.map((item) => (
              <li
                key={item.id}
                className="rounded-[16px] border border-line bg-surface px-3.5 py-3"
              >
                <div className="flex items-start justify-between gap-3">
                  <div className="min-w-0">
                    <p className="truncate text-[15px] font-bold text-ink">
                      {item.serviceEmoji} {item.serviceTitle}
                    </p>
                    <p className="mt-0.5 truncate text-[13px] text-muted">
                      {item.clientName || "Клиент"}
                    </p>
                  </div>
                  <span className="shrink-0 rounded-full bg-svc-booking/70 px-2.5 py-1 text-[11px] font-bold text-svc-booking-ink">
                    {statusLabelRu(item.status)}
                  </span>
                </div>
                <div className="mt-2 flex flex-wrap items-center gap-x-3 gap-y-1 text-[12px] text-muted">
                  <span className="font-semibold text-ink">
                    {formatBookingWhen(item.startsAt)}
                  </span>
                  <span>{formatPriceKzt(item.price)}</span>
                  <span>{item.durationMinutes} мин</span>
                </div>
              </li>
            ))}
          </ul>
        )}
      </div>
    </BookingWorkspaceShell>
  );
}
