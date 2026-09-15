"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { BookingClientShell } from "@/features/booking/components/booking-workspace-shell";
import { BookingListShimmer } from "@/features/booking/components/booking-shimmers";
import { listMyBookings } from "@/features/booking/lib/bookings-api";
import type { MyBookingItem } from "@/features/booking/lib/booking-model";
import {
  formatBookingWhen,
  formatPriceKzt,
  myBookingsRange,
  statusLabelRu,
} from "@/features/booking/lib/booking-format";

export function MyBookingsView() {
  const [items, setItems] = useState<MyBookingItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    setLoading(true);
    const { from, to } = myBookingsRange();
    void listMyBookings({ from, to })
      .then(setItems)
      .catch((e: unknown) => setError(e instanceof Error ? e.message : "Ошибка"))
      .finally(() => setLoading(false));
  }, []);

  const upcoming = items.filter(
    (i) =>
      (i.status === "confirmed" || i.status === "pending") &&
      new Date(i.startsAt).getTime() > Date.now(),
  );
  const past = items.filter((i) => !upcoming.includes(i));

  return (
    <BookingClientShell title="Мои бронирования">
      <div className="space-y-5">
        {error ? <p className="text-sm text-destructive">{error}</p> : null}
        {loading ? (
          <BookingListShimmer rows={5} />
        ) : items.length === 0 ? (
          <p className="text-sm text-muted">Пока нет записей.</p>
        ) : (
          <>
            {upcoming.length ? (
              <section>
                <p className="mb-2 text-[12px] font-bold uppercase tracking-wide text-muted">
                  Предстоящие
                </p>
                <ul className="space-y-2">
                  {upcoming.map((item) => (
                    <BookingCard key={item.id} item={item} />
                  ))}
                </ul>
              </section>
            ) : null}
            {past.length ? (
              <section>
                <p className="mb-2 text-[12px] font-bold uppercase tracking-wide text-muted">
                  История
                </p>
                <ul className="space-y-2">
                  {past.map((item) => (
                    <BookingCard key={item.id} item={item} />
                  ))}
                </ul>
              </section>
            ) : null}
          </>
        )}
      </div>
    </BookingClientShell>
  );
}

function BookingCard({ item }: { item: MyBookingItem }) {
  return (
    <li>
      <Link
        href={`/app/settings/booking/my/${item.id}`}
        className="block rounded-[16px] border border-line bg-surface px-3.5 py-3 transition hover:bg-mint/50"
      >
        <div className="flex items-start justify-between gap-2">
          <div className="min-w-0">
            <p className="text-[15px] font-bold text-ink">
              {item.serviceEmoji} {item.serviceTitle}
            </p>
            <p className="mt-0.5 text-[13px] text-muted">
              {item.hostDisplayName}
              {item.hostUsername ? ` · @${item.hostUsername}` : ""}
            </p>
            <p className="mt-1 text-[13px] font-semibold text-ink">
              {formatBookingWhen(item.startsAt)} · {formatPriceKzt(item.price)}
            </p>
            <p className="mt-1 text-[12px] font-semibold text-svc-booking-ink">
              {statusLabelRu(item.status)}
            </p>
          </div>
          <span className="shrink-0 text-[12px] font-semibold text-brand">Открыть</span>
        </div>
      </Link>
    </li>
  );
}
