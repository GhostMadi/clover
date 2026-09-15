"use client";

import { useEffect, useMemo, useState, type ReactNode } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { AppButton } from "@/components/shared/app-button";
import { BookingClientShell } from "@/features/booking/components/booking-workspace-shell";
import {
  BookingDetailShimmer,
  BookingSlotsShimmer,
} from "@/features/booking/components/booking-shimmers";
import {
  getBookingForViewer,
  rescheduleBooking,
  updateBookingStatus,
} from "@/features/booking/lib/bookings-api";
import { getBookingAvailability } from "@/features/booking/lib/client-api";
import type { MyBookingItem } from "@/features/booking/lib/booking-model";
import {
  addDays,
  canClientCancel,
  dateKeyLocal,
  endsAt,
  formatBookingWhen,
  formatPriceKzt,
  formatSlotTime,
  startOfLocalDay,
  statusLabelRu,
} from "@/features/booking/lib/booking-format";

export function MyBookingDetailView({ bookingId }: { bookingId: string }) {
  const router = useRouter();
  const [item, setItem] = useState<MyBookingItem | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);
  const [rescheduleOpen, setRescheduleOpen] = useState(false);
  const [day, setDay] = useState(() => startOfLocalDay());
  const [slots, setSlots] = useState<{ startsAt: string }[]>([]);
  const [slotsLoading, setSlotsLoading] = useState(false);

  const reload = () => {
    setLoading(true);
    setError(null);
    void getBookingForViewer(bookingId)
      .then((res) => {
        if (!res) {
          setItem(null);
          setError("Запись не найдена");
          return;
        }
        if (res.role === "host") {
          router.replace(`/app/settings/booking/inbox/${res.item.id}`);
          return;
        }
        setItem(res.item);
      })
      .catch((e: unknown) => {
        setItem(null);
        setError(e instanceof Error ? e.message : "Ошибка");
      })
      .finally(() => setLoading(false));
  };

  useEffect(() => {
    reload();
    // eslint-disable-next-line react-hooks/exhaustive-deps -- reload on id
  }, [bookingId]);

  useEffect(() => {
    if (!rescheduleOpen || !item?.hostId || !item.serviceId || !item.staffId) {
      setSlots([]);
      return;
    }
    let cancelled = false;
    setSlotsLoading(true);
    void getBookingAvailability({
      hostId: item.hostId,
      serviceId: item.serviceId,
      staffId: item.staffId,
      day,
      excludeBookingId: item.id,
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
  }, [rescheduleOpen, item, day]);

  const canAct =
    !!item &&
    (item.status === "confirmed" || item.status === "pending") &&
    canClientCancel(item.startsAt, item.clientCancelHoursBefore);

  const endLabel = useMemo(() => {
    if (!item) return null;
    const end = endsAt(item.startsAt, item.durationMinutes);
    return formatSlotTime(end.toISOString());
  }, [item]);

  const onCancel = async () => {
    if (!item || busy || !canAct) return;
    setBusy(true);
    setError(null);
    try {
      await updateBookingStatus(item.id, "cancelled");
      reload();
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : "Не удалось отменить");
    } finally {
      setBusy(false);
    }
  };

  const onPickSlot = async (startsAt: string) => {
    if (!item?.staffId || busy) return;
    setBusy(true);
    setError(null);
    try {
      await rescheduleBooking({
        bookingId: item.id,
        staffId: item.staffId,
        startsAt,
      });
      setRescheduleOpen(false);
      reload();
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : "Не удалось перенести");
    } finally {
      setBusy(false);
    }
  };

  const days = useMemo(
    () => Array.from({ length: 10 }, (_, i) => addDays(startOfLocalDay(), i)),
    [],
  );

  return (
    <BookingClientShell title="Запись" backHref="/app/settings/booking/my">
      <div className="space-y-4">
        {loading ? (
          <BookingDetailShimmer />
        ) : !item ? (
          <p className="text-sm text-muted">{error ?? "Нет данных"}</p>
        ) : (
          <>
            <div className="rounded-[16px] border border-svc-booking-ink/25 bg-svc-booking/40 px-3.5 py-3.5">
              <div className="flex items-start gap-3">
                <span className="flex h-14 w-14 shrink-0 items-center justify-center rounded-[16px] bg-surface text-[28px]">
                  {item.serviceEmoji}
                </span>
                <div className="min-w-0">
                  <p className="text-[18px] font-bold text-ink">{item.serviceTitle}</p>
                  <p className="mt-1 text-[13px] font-semibold text-muted">
                    {item.hostDisplayName}
                    {item.hostUsername ? ` · @${item.hostUsername}` : ""}
                  </p>
                  <p className="mt-2 text-[13px] font-bold text-svc-booking-ink">
                    {statusLabelRu(item.status)}
                  </p>
                </div>
              </div>
            </div>

            <DetailSection title="Мастер / салон">
              <DetailRow label="Название" value={item.hostDisplayName} />
              {item.hostUsername ? (
                <DetailRow label="Аккаунт" value={`@${item.hostUsername}`} />
              ) : null}
              <div className="pt-1">
                <Link
                  href={`/app/u/${item.hostId}`}
                  className="text-[13px] font-semibold text-brand"
                >
                  Открыть профиль
                </Link>
              </div>
            </DetailSection>

            <DetailSection title="Время">
              <DetailRow label="Дата и начало" value={formatBookingWhen(item.startsAt)} />
              <DetailRow
                label="Окончание"
                value={
                  endLabel
                    ? `${endLabel} · ${item.durationMinutes} мин`
                    : `${item.durationMinutes} мин`
                }
              />
            </DetailSection>

            <DetailSection title="Услуга">
              <DetailRow label="Название" value={item.serviceTitle} />
              <DetailRow label="Длительность" value={`${item.durationMinutes} мин`} />
              <DetailRow label="Цена" value={formatPriceKzt(item.price)} />
            </DetailSection>

            {item.executorName ? (
              <DetailSection title="Исполнитель">
                <DetailRow label="Мастер" value={item.executorName} />
              </DetailSection>
            ) : null}

            {item.notes?.trim() ? (
              <DetailSection title="Заметка">
                <p className="whitespace-pre-wrap text-[14px] font-semibold text-ink">
                  {item.notes.trim()}
                </p>
              </DetailSection>
            ) : null}

            {error ? <p className="text-sm text-destructive">{error}</p> : null}

            {canAct ? (
              <div className="space-y-2 pt-1">
                <AppButton
                  service="booking"
                  onClick={() => {
                    setRescheduleOpen(true);
                    setDay(startOfLocalDay(new Date(item.startsAt)));
                  }}
                >
                  Перенести
                </AppButton>
                <AppButton variant="outline" loading={busy} onClick={() => void onCancel()}>
                  Отменить
                </AppButton>
              </div>
            ) : null}
          </>
        )}

        {rescheduleOpen && item ? (
          <div className="fixed inset-0 z-50 flex items-end justify-center bg-ink/40 p-0 sm:items-center sm:p-4">
            <div className="max-h-[85dvh] w-full max-w-md overflow-y-auto rounded-t-2xl border border-line bg-surface p-4 shadow-elevate-lg sm:rounded-2xl">
              <p className="text-[16px] font-bold text-ink">Перенос записи</p>
              <p className="mt-1 text-[13px] text-muted">
                {item.serviceEmoji} {item.serviceTitle}
              </p>
              <div className="mt-3 flex gap-2 overflow-x-auto pb-1">
                {days.map((d) => {
                  const key = dateKeyLocal(d);
                  const on = dateKeyLocal(day) === key;
                  return (
                    <button
                      key={key}
                      type="button"
                      onClick={() => setDay(d)}
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
                      disabled={busy}
                      onClick={() => void onPickSlot(s.startsAt)}
                      className="rounded-[12px] border border-line px-3 py-2 text-[13px] font-semibold hover:bg-svc-booking/50 disabled:opacity-60"
                    >
                      {formatSlotTime(s.startsAt)}
                    </button>
                  ))
                )}
              </div>
              <AppButton
                variant="outline"
                className="mt-4"
                onClick={() => setRescheduleOpen(false)}
              >
                Закрыть
              </AppButton>
            </div>
          </div>
        ) : null}
      </div>
    </BookingClientShell>
  );
}

function DetailSection({
  title,
  children,
}: {
  title: string;
  children: ReactNode;
}) {
  return (
    <section className="rounded-[16px] border border-line bg-surface px-3.5 py-3.5">
      <p className="mb-2.5 text-[13px] font-bold text-muted">{title}</p>
      <div className="space-y-2.5">{children}</div>
    </section>
  );
}

function DetailRow({ label, value }: { label: string; value: string }) {
  return (
    <div className="flex gap-3 text-[13px]">
      <span className="w-[7.5rem] shrink-0 font-semibold text-muted">{label}</span>
      <span className="min-w-0 flex-1 font-semibold text-ink">{value}</span>
    </div>
  );
}
