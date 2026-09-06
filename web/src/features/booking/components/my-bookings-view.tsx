"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { AppButton } from "@/components/shared/app-button";
import { SettingsShell } from "@/features/settings/components/settings-shell";
import {
  BookingListShimmer,
  BookingSlotsShimmer,
} from "@/features/booking/components/booking-shimmers";
import {
  listMyBookings,
  rescheduleBooking,
  updateBookingStatus,
} from "@/features/booking/lib/bookings-api";
import { getBookingAvailability } from "@/features/booking/lib/client-api";
import type { MyBookingItem } from "@/features/booking/lib/booking-model";
import {
  canClientCancel,
  formatBookingWhen,
  formatPriceKzt,
  formatSlotTime,
  myBookingsRange,
  statusLabelRu,
  addDays,
  dateKeyLocal,
  startOfLocalDay,
} from "@/features/booking/lib/booking-format";

export function MyBookingsView() {
  const [items, setItems] = useState<MyBookingItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [busyId, setBusyId] = useState<string | null>(null);
  const [rescheduleId, setRescheduleId] = useState<string | null>(null);
  const [rescheduleDay, setRescheduleDay] = useState(() => startOfLocalDay());
  const [slots, setSlots] = useState<{ startsAt: string }[]>([]);
  const [slotsLoading, setSlotsLoading] = useState(false);

  const reload = () => {
    setLoading(true);
    const { from, to } = myBookingsRange();
    void listMyBookings({ from, to })
      .then(setItems)
      .catch((e: unknown) => setError(e instanceof Error ? e.message : "Ошибка"))
      .finally(() => setLoading(false));
  };

  useEffect(() => {
    reload();
  }, []);

  const active = rescheduleId ? items.find((i) => i.id === rescheduleId) : null;

  useEffect(() => {
    if (!active?.hostId || !active.serviceId || !active.staffId) {
      setSlots([]);
      return;
    }
    let cancelled = false;
    setSlotsLoading(true);
    void getBookingAvailability({
      hostId: active.hostId,
      serviceId: active.serviceId,
      staffId: active.staffId,
      day: rescheduleDay,
      excludeBookingId: active.id,
    })
      .then((res) => {
        if (!cancelled) {
          setSlots(res.slots.filter((s) => s.status === "available"));
        }
      })
      .catch(() => {
        if (!cancelled) setSlots([]);
      })
      .finally(() => {
        if (!cancelled) setSlotsLoading(false);
      });
    return () => {
      cancelled = true;
    };
  }, [active, rescheduleDay]);

  const onCancel = async (item: MyBookingItem) => {
    if (busyId) return;
    setBusyId(item.id);
    setError(null);
    try {
      await updateBookingStatus(item.id, "cancelled");
      reload();
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : "Не удалось отменить");
    } finally {
      setBusyId(null);
    }
  };

  const onPickSlot = async (startsAt: string) => {
    if (!active?.staffId || busyId) return;
    setBusyId(active.id);
    try {
      await rescheduleBooking({
        bookingId: active.id,
        staffId: active.staffId,
        startsAt,
      });
      setRescheduleId(null);
      reload();
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : "Не удалось перенести");
    } finally {
      setBusyId(null);
    }
  };

  const upcoming = items.filter(
    (i) =>
      (i.status === "confirmed" || i.status === "pending") &&
      new Date(i.startsAt).getTime() > Date.now(),
  );
  const past = items.filter((i) => !upcoming.includes(i));

  return (
    <SettingsShell title="Мои бронирования" backHref="/app/settings/booking" service="booking">
      <div className="space-y-5 px-4 py-5">
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
                    <BookingCard
                      key={item.id}
                      item={item}
                      busy={busyId === item.id}
                      onCancel={() => void onCancel(item)}
                      onReschedule={() => {
                        setRescheduleId(item.id);
                        setRescheduleDay(startOfLocalDay());
                      }}
                    />
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

        {active ? (
          <div className="fixed inset-0 z-50 flex items-end justify-center bg-ink/40 p-0 sm:items-center sm:p-4">
            <div className="max-h-[85dvh] w-full max-w-md overflow-y-auto rounded-t-2xl border border-line bg-surface p-4 shadow-elevate-lg sm:rounded-2xl">
              <p className="text-[16px] font-bold text-ink">Перенос записи</p>
              <p className="mt-1 text-[13px] text-muted">
                {active.serviceEmoji} {active.serviceTitle}
              </p>
              <div className="mt-3 flex gap-2 overflow-x-auto pb-1">
                {Array.from({ length: 10 }, (_, i) => addDays(startOfLocalDay(), i)).map((d) => {
                  const key = dateKeyLocal(d);
                  const on = dateKeyLocal(rescheduleDay) === key;
                  return (
                    <button
                      key={key}
                      type="button"
                      onClick={() => setRescheduleDay(d)}
                      className={`shrink-0 rounded-[12px] px-3 py-2 text-[12px] font-semibold ${
                        on ? "bg-svc-booking text-svc-booking-ink" : "border border-line"
                      }`}
                    >
                      {d.toLocaleDateString("ru-RU", { day: "numeric", month: "short" })}
                    </button>
                  );
                })}
              </div>
              <div className="mt-3 flex flex-wrap gap-2">
                {slotsLoading ? (
                  <BookingSlotsShimmer count={6} />
                ) : slots.length === 0 ? (
                  <p className="text-sm text-muted">Нет свободных слотов</p>
                ) : (
                  slots.map((s) => (
                    <button
                      key={s.startsAt}
                      type="button"
                      onClick={() => void onPickSlot(s.startsAt)}
                      className="rounded-[12px] border border-line px-3 py-2 text-[13px] font-semibold hover:bg-svc-booking/50"
                    >
                      {formatSlotTime(s.startsAt)}
                    </button>
                  ))
                )}
              </div>
              <AppButton
                variant="outline"
                className="mt-4"
                onClick={() => setRescheduleId(null)}
              >
                Закрыть
              </AppButton>
            </div>
          </div>
        ) : null}
      </div>
    </SettingsShell>
  );
}

function BookingCard({
  item,
  busy,
  onCancel,
  onReschedule,
}: {
  item: MyBookingItem;
  busy?: boolean;
  onCancel?: () => void;
  onReschedule?: () => void;
}) {
  const canCancel =
    onCancel &&
    (item.status === "confirmed" || item.status === "pending") &&
    canClientCancel(item.startsAt, item.clientCancelHoursBefore);

  return (
    <li className="rounded-[16px] border border-line bg-surface px-3.5 py-3">
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
        <Link
          href={`/app/u/${item.hostId}`}
          className="shrink-0 text-[12px] font-semibold text-brand"
        >
          Профиль
        </Link>
      </div>
      {canCancel || onReschedule ? (
        <div className="mt-3 flex gap-2">
          {onReschedule && canCancel ? (
            <AppButton variant="outline" size="row" className="flex-1" onClick={onReschedule}>
              Перенести
            </AppButton>
          ) : null}
          {canCancel ? (
            <AppButton
              variant="outline"
              size="row"
              className="flex-1"
              loading={busy}
              onClick={onCancel}
            >
              Отменить
            </AppButton>
          ) : null}
        </div>
      ) : null}
    </li>
  );
}
