"use client";

import { useEffect, useMemo, useState } from "react";
import { useRouter } from "next/navigation";
import { AppButton } from "@/components/shared/app-button";
import { BookingWorkspaceShell } from "@/features/booking/components/booking-workspace-shell";
import {
  BookingDetailShimmer,
  BookingSlotsShimmer,
} from "@/features/booking/components/booking-shimmers";
import {
  listHostBookings,
  rescheduleBooking,
  revertBookingStatus,
  updateBookingStatus,
} from "@/features/booking/lib/bookings-api";
import { getBookingAvailability } from "@/features/booking/lib/client-api";
import type { BookingStatus, HostBookingItem } from "@/features/booking/lib/booking-model";
import {
  addDays,
  dateKeyLocal,
  formatBookingWhen,
  formatPriceKzt,
  formatSlotTime,
  hostInboxRange,
  startOfLocalDay,
  statusLabelRu,
} from "@/features/booking/lib/booking-format";

const NEXT_STATUS: Partial<Record<BookingStatus, BookingStatus>> = {
  confirmed: "client_arrived",
  client_arrived: "in_progress",
  in_progress: "completed",
};

const NEXT_LABEL: Partial<Record<BookingStatus, string>> = {
  confirmed: "Клиент пришёл",
  client_arrived: "В работу",
  in_progress: "Оказана",
};

export function HostBookingDetailView({ bookingId }: { bookingId: string }) {
  const router = useRouter();
  const [item, setItem] = useState<HostBookingItem | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);
  const [rescheduleOpen, setRescheduleOpen] = useState(false);
  const [day, setDay] = useState(() => startOfLocalDay());
  const [slots, setSlots] = useState<{ startsAt: string }[]>([]);
  const [slotsLoading, setSlotsLoading] = useState(false);

  const reload = () => {
    setLoading(true);
    const { from, to } = hostInboxRange();
    void listHostBookings({ from, to, limit: 200 })
      .then((list) => {
        const found = list.find((b) => b.id === bookingId) ?? null;
        setItem(found);
        if (!found) setError("Запись не найдена в текущем окне");
      })
      .catch((e: unknown) => setError(e instanceof Error ? e.message : "Ошибка"))
      .finally(() => setLoading(false));
  };

  useEffect(() => {
    reload();
  }, [bookingId]);

  useEffect(() => {
    if (!rescheduleOpen || !item?.serviceId || !item.staffId) return;
    let cancelled = false;
    setSlotsLoading(true);
    setSlots([]);
    void (async () => {
      const { createClient } = await import("@/lib/supabase/client");
      const {
        data: { user },
      } = await createClient().auth.getUser();
      if (!user || !item.serviceId || !item.staffId) return;
      try {
        const res = await getBookingAvailability({
          hostId: user.id,
          serviceId: item.serviceId,
          staffId: item.staffId,
          day,
          excludeBookingId: item.id,
        });
        if (!cancelled) setSlots(res.slots.filter((s) => s.status === "available"));
      } catch {
        if (!cancelled) setSlots([]);
      } finally {
        if (!cancelled) setSlotsLoading(false);
      }
    })();
    return () => {
      cancelled = true;
    };
  }, [rescheduleOpen, item, day]);

  const next = item ? NEXT_STATUS[item.status] : undefined;
  const nextLabel = item ? NEXT_LABEL[item.status] : undefined;

  const runStatus = async (status: BookingStatus) => {
    if (!item || busy) return;
    setBusy(true);
    setError(null);
    try {
      await updateBookingStatus(item.id, status);
      reload();
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : "Не удалось обновить статус");
    } finally {
      setBusy(false);
    }
  };

  const days = useMemo(
    () => Array.from({ length: 10 }, (_, i) => addDays(startOfLocalDay(), i)),
    [],
  );

  return (
    <BookingWorkspaceShell title="Запись" backHref="/app/settings/booking/inbox">
      <div className="mx-auto max-w-2xl space-y-4">
        {loading ? (
          <BookingDetailShimmer />
        ) : !item ? (
          <p className="text-sm text-muted">{error ?? "Нет данных"}</p>
        ) : (
          <>
            <div className="rounded-[16px] border border-line bg-surface px-3.5 py-3.5">
              <p className="text-[18px] font-bold text-ink">
                {item.serviceEmoji} {item.serviceTitle}
              </p>
              <p className="mt-2 text-[14px] text-ink">
                {item.clientName}
                {item.clientUsername ? (
                  <span className="text-muted"> · @{item.clientUsername}</span>
                ) : null}
              </p>
              {item.clientPhone ? (
                <p className="mt-1 text-[13px] text-muted">{item.clientPhone}</p>
              ) : null}
              <p className="mt-3 text-[14px] font-semibold text-ink">
                {formatBookingWhen(item.startsAt)}
              </p>
              <p className="mt-1 text-[13px] text-muted">
                {item.durationMinutes} мин · {formatPriceKzt(item.price)}
                {item.executorName ? ` · ${item.executorName}` : ""}
              </p>
              <p className="mt-2 text-[13px] font-bold text-svc-booking-ink">
                {statusLabelRu(item.status)}
              </p>
              {item.notes ? (
                <p className="mt-3 whitespace-pre-wrap text-[13px] text-muted">{item.notes}</p>
              ) : null}
            </div>

            {error ? <p className="text-sm text-destructive">{error}</p> : null}

            <div className="space-y-2">
              {next && nextLabel ? (
                <AppButton service="booking" loading={busy} onClick={() => void runStatus(next)}>
                  {nextLabel}
                </AppButton>
              ) : null}
              {item.status === "confirmed" || item.status === "pending" ? (
                <>
                  <AppButton
                    variant="outline"
                    onClick={() => {
                      setRescheduleOpen(true);
                      setDay(startOfLocalDay(new Date(item.startsAt)));
                    }}
                  >
                    Перенести
                  </AppButton>
                  <AppButton
                    variant="outline"
                    loading={busy}
                    onClick={() => void runStatus("cancelled")}
                  >
                    Отменить
                  </AppButton>
                  <AppButton
                    variant="outline"
                    loading={busy}
                    onClick={() => void runStatus("no_show")}
                  >
                    Не пришёл
                  </AppButton>
                </>
              ) : null}
              {item.status === "client_arrived" || item.status === "in_progress" ? (
                <AppButton
                  variant="outline"
                  loading={busy}
                  onClick={async () => {
                    setBusy(true);
                    try {
                      await revertBookingStatus(item.id);
                      reload();
                    } catch (e: unknown) {
                      setError(e instanceof Error ? e.message : "Ошибка");
                    } finally {
                      setBusy(false);
                    }
                  }}
                >
                  Откатить статус
                </AppButton>
              ) : null}
            </div>

            {item.clientId ? (
              <button
                type="button"
                className="text-[13px] font-semibold text-brand"
                onClick={() => router.push(`/app/u/${item.clientId}`)}
              >
                Открыть профиль клиента
              </button>
            ) : null}
          </>
        )}

        {rescheduleOpen && item?.staffId ? (
          <div className="fixed inset-0 z-50 flex items-end justify-center bg-ink/40 sm:items-center sm:p-4">
            <div className="max-h-[85dvh] w-full max-w-md overflow-y-auto rounded-t-2xl border border-line bg-surface p-4 sm:rounded-2xl">
              <p className="text-[16px] font-bold text-ink">Перенос</p>
              <div className="mt-3 flex gap-2 overflow-x-auto">
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
                    className="rounded-[12px] border border-line px-3 py-2 text-[13px] font-semibold"
                    onClick={() => {
                      void (async () => {
                        if (!item.staffId) return;
                        setBusy(true);
                        try {
                          await rescheduleBooking({
                            bookingId: item.id,
                            staffId: item.staffId,
                            startsAt: s.startsAt,
                          });
                          setRescheduleOpen(false);
                          reload();
                        } catch (e: unknown) {
                          setError(e instanceof Error ? e.message : "Ошибка переноса");
                        } finally {
                          setBusy(false);
                        }
                      })();
                    }}
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
    </BookingWorkspaceShell>
  );
}
