"use client";

import Link from "next/link";
import { useEffect, useMemo, useState } from "react";
import { BookingWorkspaceShell } from "@/features/booking/components/booking-workspace-shell";
import {
  bookingPointBase,
  readBookingInboxCache,
  writeBookingInboxCache,
} from "@/features/booking/lib/booking-prefs";
import { BookingListShimmer } from "@/features/booking/components/booking-shimmers";
import { loadHostInbox } from "@/features/booking/lib/bookings-api";
import type { HostBookingItem } from "@/features/booking/lib/booking-model";
import {
  endsAt,
  formatBookingWhen,
  formatPriceKzt,
  hostInboxRange,
  statusLabelRu,
} from "@/features/booking/lib/booking-format";
import { runServiceSwr } from "@/lib/run-service-swr";
import {
  ServiceEmpty,
  ServiceInformer,
  ServiceSection,
} from "@/features/shared/components/service-page";

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

function hubPulse(inChair: number, upcoming: number): string {
  if (inChair === 0 && upcoming === 0) {
    return "Сейчас никто не в кресле и ближайших записей нет — откройте календарь дня.";
  }
  const chair = inChair === 0 ? "в кресле никого" : `в кресле ${inChair}`;
  const next = upcoming === 0 ? "ближайших нет" : `ближайших ${upcoming}`;
  return `Сейчас ${chair} · ${next}.`;
}

export function BookingHubView({ pointId }: { pointId: string }) {
  const [items, setItems] = useState<HostBookingItem[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    let cancelled = false;
    const range = hostInboxRange();
    void runServiceSwr({
      read: (uid) => readBookingInboxCache(uid, pointId, range),
      fetch: () => loadHostInbox({ pointId, from: range.from, to: range.to }),
      write: (uid, data) => writeBookingInboxCache(uid, pointId, range, data),
      apply: (data) => {
        if (!cancelled) setItems(data);
      },
      setLoading: (value) => {
        if (!cancelled) setLoading(value);
      },
    });
    return () => {
      cancelled = true;
    };
  }, [pointId]);

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
  const base = bookingPointBase(pointId);

  return (
    <BookingWorkspaceShell
      pointId={pointId}
      title="Обзор"
      lead="Что происходит на точке: кто в кресле и кто придёт дальше."
    >
      <div className="space-y-6">
        {!loading || items.length > 0 ? (
          <ServiceInformer
            service="booking"
            tone={inChair.length > 0 || upcoming.length > 0 ? "next" : "info"}
          >
            {hubPulse(inChair.length, upcoming.length)}
          </ServiceInformer>
        ) : null}

        <div className="grid gap-4 lg:grid-cols-2">
          <div className="rounded-[16px] border border-line bg-surface p-4">
            <ServiceSection
              title="Сейчас в кресле"
              action={
                <Link
                  href={`${base}/inbox`}
                  className="text-[12px] font-bold text-svc-booking-ink hover:underline"
                >
                  Все записи
                </Link>
              }
            >
              {loading && items.length === 0 ? (
                <BookingListShimmer rows={2} />
              ) : inChair.length === 0 ? (
                <ServiceEmpty>Сейчас никто не на приёме.</ServiceEmpty>
              ) : (
                <ul className="space-y-2">
                  {inChair.map((item) => (
                    <li key={item.id}>
                      <Link
                        href={`${base}/inbox/${item.id}`}
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
            </ServiceSection>
          </div>

          <div className="rounded-[16px] border border-line bg-surface p-4">
            <ServiceSection
              title="Ближайшие"
              action={
                <span className="text-[11px] text-muted">
                  {upcoming.length === 0 ? "пока пусто" : `${upcoming.length} впереди`}
                </span>
              }
            >
              {loading && items.length === 0 ? (
                <BookingListShimmer rows={3} />
              ) : upcoming.length === 0 ? (
                <ServiceEmpty>Ближайших записей нет.</ServiceEmpty>
              ) : (
                <ul className="divide-y divide-line">
                  {upcoming.map((item) => (
                    <li key={item.id}>
                      <Link
                        href={`${base}/inbox/${item.id}`}
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
            </ServiceSection>
          </div>
        </div>
      </div>
    </BookingWorkspaceShell>
  );
}
