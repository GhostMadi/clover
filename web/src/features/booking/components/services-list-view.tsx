"use client";

import { useCallback, useEffect, useId, useState } from "react";
import Link from "next/link";
import { Plus, X } from "lucide-react";
import { AppButton, AppButtonLink } from "@/components/shared/app-button";
import { AddStaffModal } from "@/features/booking/components/add-staff-modal";
import { BookingListShimmer } from "@/features/booking/components/booking-shimmers";
import {
  bookingPointBase,
  readBookingServicesCache,
  writeBookingServicesCache,
} from "@/features/booking/lib/booking-prefs";
import { BookingWorkspaceShell } from "@/features/booking/components/booking-workspace-shell";
import { listMyServices } from "@/features/booking/lib/services-api";
import {
  cancelStaffInvite,
  listMyStaff,
  listPendingStaffInvites,
  setStaffActive,
  type BookingStaffInvite,
} from "@/features/booking/lib/staff-api";
import type { BookingService, BookingStaff } from "@/features/booking/lib/booking-model";
import { formatPriceKzt } from "@/features/booking/lib/booking-format";
import {
  ServiceEmpty,
  ServiceInformer,
  ServiceSection,
} from "@/features/shared/components/service-page";
import { createClient } from "@/lib/supabase/client";

export function ServicesListView({ pointId }: { pointId: string }) {
  const [services, setServices] = useState<BookingService[]>([]);
  const [staff, setStaff] = useState<BookingStaff[]>([]);
  const [pending, setPending] = useState<BookingStaffInvite[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [addOpen, setAddOpen] = useState(false);
  const [staffToRemove, setStaffToRemove] = useState<BookingStaff | null>(null);
  const [staffBusyId, setStaffBusyId] = useState<string | null>(null);
  const removeTitleId = useId();

  const reload = useCallback(
    async (opts?: { soft?: boolean }) => {
      if (!opts?.soft) setLoading(true);
      setError(null);
      try {
        const {
          data: { session },
        } = await createClient().auth.getSession();
        const uid = session?.user.id ?? null;
        const [s, st, inv] = await Promise.all([
          listMyServices(pointId),
          listMyStaff(true),
          listPendingStaffInvites(),
        ]);
        setServices(s);
        setStaff(st);
        setPending(inv);
        writeBookingServicesCache(uid, pointId, { services: s, staff: st });
      } catch (e: unknown) {
        setError(e instanceof Error ? e.message : "Ошибка");
      } finally {
        setLoading(false);
      }
    },
    [pointId],
  );

  useEffect(() => {
    let cancelled = false;
    void (async () => {
      const {
        data: { session },
      } = await createClient().auth.getSession();
      if (cancelled) return;
      const uid = session?.user.id ?? null;
      const cached = readBookingServicesCache(uid, pointId);
      if (cached) {
        setServices(cached.services);
        setStaff(cached.staff.filter((s) => s.isActive));
        setLoading(false);
        await reload({ soft: true });
      } else {
        await reload();
      }
    })();
    return () => {
      cancelled = true;
    };
  }, [pointId, reload]);

  const removeStaff = async (s: BookingStaff): Promise<boolean> => {
    if (staffBusyId) return false;
    setStaffBusyId(s.id);
    setError(null);
    const previous = staff;
    setStaff((list) => list.filter((item) => item.id !== s.id));
    try {
      await setStaffActive(s.id, false);
      await reload({ soft: true });
      return true;
    } catch (e: unknown) {
      setStaff(previous);
      setError(e instanceof Error ? e.message : "Не удалось убрать мастера");
      return false;
    } finally {
      setStaffBusyId(null);
    }
  };

  const cancelInvite = async (inviteId: string) => {
    setError(null);
    try {
      await cancelStaffInvite(inviteId);
      await reload({ soft: true });
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : "Не удалось отменить");
    }
  };

  return (
    <BookingWorkspaceShell
      pointId={pointId}
      title="Услуги"
      lead="Что клиент может забронировать и кто это делает."
      trailing={
        <AppButtonLink
          href={`${bookingPointBase(pointId)}/services/new`}
          size="icon"
          service="booking"
          title="Новая услуга"
          aria-label="Новая услуга"
        >
          <Plus strokeWidth={2.5} />
        </AppButtonLink>
      }
    >
      <div className="mx-auto max-w-3xl space-y-4">
        {error ? (
          <ServiceInformer service="booking" tone="warning">
            {error}
          </ServiceInformer>
        ) : null}

        <Link
          href={`${bookingPointBase(pointId)}/visual`}
          className="flex items-center gap-3 rounded-[16px] border border-line bg-svc-booking/35 px-4 py-3 transition hover:bg-svc-booking/55"
        >
          <span className="text-[28px] leading-none">✂️</span>
          <span className="min-w-0 flex-1">
            <span className="block text-[14px] font-bold text-ink">Схема и ценники</span>
            <span className="block text-[12px] text-muted">
              Привяжите схему из Ресурсов · цена только на emoji · услуга + мастер
            </span>
          </span>
        </Link>

        <section className="space-y-3 rounded-[16px] border border-line bg-surface p-4">
          <ServiceSection
            title="Каталог"
            action={
              <AppButtonLink
                href={`${bookingPointBase(pointId)}/services/new`}
                size="row"
                service="booking"
              >
                Новая услуга
              </AppButtonLink>
            }
          >
            <ServiceInformer service="booking">
              Что клиент выбирает при записи: название, длительность и цена. Нажмите
              строку, чтобы изменить услугу.
            </ServiceInformer>
          </ServiceSection>
          {loading ? (
            <BookingListShimmer rows={4} />
          ) : services.length === 0 ? (
            <ServiceEmpty
              action={
                <AppButtonLink
                  href={`${bookingPointBase(pointId)}/services/new`}
                  size="row"
                  service="booking"
                >
                  Добавить услугу
                </AppButtonLink>
              }
            >
              Пока нет услуг. Создайте первую — клиент увидит её при записи.
            </ServiceEmpty>
          ) : (
            <ul className="overflow-hidden rounded-[16px] border border-line bg-bg">
              {services.map((s, i) => (
                <li key={s.id} className={i > 0 ? "border-t border-line" : ""}>
                  <Link
                    href={`${bookingPointBase(pointId)}/services/${s.id}`}
                    className="flex items-center gap-3 px-3.5 py-3.5 transition hover:bg-svc-booking/40"
                  >
                    <span className="text-xl">{s.emojiText}</span>
                    <span className="min-w-0 flex-1">
                      <span className="block text-[15px] font-bold text-ink">
                        {s.title}
                        {!s.isActive ? (
                          <span className="ml-2 text-[11px] font-semibold text-muted">
                            скрыта
                          </span>
                        ) : null}
                      </span>
                      <span className="block text-[12px] text-muted">
                        {s.durationMinutes} мин · {formatPriceKzt(s.price)} · мастеров{" "}
                        {s.executorIds.length}
                      </span>
                    </span>
                  </Link>
                </li>
              ))}
            </ul>
          )}
        </section>

        <section className="space-y-3 rounded-[16px] border border-line bg-surface p-4">
          <ServiceSection
            title="Мастера"
            action={
              <AppButton size="row" service="booking" onClick={() => setAddOpen(true)}>
                <span className="inline-flex items-center gap-1.5">
                  <Plus className="h-4 w-4" strokeWidth={2.5} />
                  Добавить
                </span>
              </AppButton>
            }
          >
            <ServiceInformer service="booking">
              Кто принимает клиентов. «Убрать» скрывает мастера из новой записи. Прошлые
              визиты остаются.
            </ServiceInformer>
          </ServiceSection>
          {loading ? (
            <BookingListShimmer rows={3} />
          ) : (
            <>
              {pending.length > 0 ? (
                <div className="space-y-1.5">
                  <p className="text-[12px] font-semibold text-muted">Ждут ответ в чате</p>
                  {pending.map((inv) => {
                    const label =
                      inv.inviteeDisplayName.trim() ||
                      inv.inviteeUsername?.trim() ||
                      "Аккаунт";
                    return (
                      <div
                        key={inv.id}
                        className="flex items-center justify-between gap-2 rounded-[12px] border border-dashed border-line bg-bg px-3 py-2.5"
                      >
                        <span className="min-w-0 truncate text-[14px] font-semibold text-ink">
                          {label}
                          {inv.inviteeUsername ? (
                            <span className="ml-1 text-[12px] font-medium text-muted">
                              @{inv.inviteeUsername}
                            </span>
                          ) : null}
                        </span>
                        <button
                          type="button"
                          className="shrink-0 text-[12px] font-bold text-destructive"
                          onClick={() => void cancelInvite(inv.id)}
                        >
                          Отменить
                        </button>
                      </div>
                    );
                  })}
                </div>
              ) : null}
              {staff.length === 0 ? (
                <ServiceEmpty>Пока нет мастеров. Добавьте, кто принимает клиентов.</ServiceEmpty>
              ) : (
                <ul className="space-y-1.5">
                  {staff.map((s) => (
                    <li
                      key={s.id}
                      className="flex items-center justify-between gap-2 rounded-[12px] border border-line bg-bg px-3 py-2.5"
                    >
                      <span className="min-w-0 truncate text-[14px] font-semibold text-ink">
                        {s.displayName}
                      </span>
                      <button
                        type="button"
                        disabled={staffBusyId === s.id}
                        className="shrink-0 text-[12px] font-bold text-destructive disabled:opacity-50"
                        onClick={() => setStaffToRemove(s)}
                      >
                        {staffBusyId === s.id ? "Убираем…" : "Убрать"}
                      </button>
                    </li>
                  ))}
                </ul>
              )}
            </>
          )}
        </section>
      </div>

      {staffToRemove ? (
        <div
          className="fixed inset-0 z-50 flex items-end justify-center bg-ink/50 p-0 sm:items-center sm:p-4"
          role="dialog"
          aria-modal="true"
          aria-labelledby={removeTitleId}
          onClick={() => {
            if (!staffBusyId) setStaffToRemove(null);
          }}
        >
          <div
            className="w-full max-w-md rounded-t-2xl border border-line bg-surface shadow-elevate-lg sm:rounded-2xl"
            onClick={(e) => e.stopPropagation()}
          >
            <div className="flex items-center gap-2 border-b border-line px-3 py-2.5">
              <h2 id={removeTitleId} className="min-w-0 flex-1 text-[16px] font-bold text-ink">
                Убрать мастера?
              </h2>
              <button
                type="button"
                onClick={() => setStaffToRemove(null)}
                disabled={staffBusyId === staffToRemove.id}
                className="flex h-10 w-10 items-center justify-center rounded-full text-ink hover:bg-bg disabled:opacity-50"
                aria-label="Закрыть"
              >
                <X className="h-5 w-5" strokeWidth={2} />
              </button>
            </div>
            <div className="space-y-4 px-4 py-4">
              <p className="text-[14px] leading-snug text-ink">
                {staffToRemove.displayName} больше не появится в новой записи. Прошлые
                визиты останутся.
              </p>
              {error ? <p className="text-[13px] text-destructive">{error}</p> : null}
              <div className="flex gap-2">
                <AppButton
                  variant="outline"
                  className="flex-1"
                  disabled={staffBusyId === staffToRemove.id}
                  onClick={() => setStaffToRemove(null)}
                >
                  Оставить
                </AppButton>
                <AppButton
                  service="booking"
                  className="flex-1"
                  loading={staffBusyId === staffToRemove.id}
                  onClick={() => {
                    const person = staffToRemove;
                    void removeStaff(person).then((ok) => {
                      if (ok) setStaffToRemove(null);
                    });
                  }}
                >
                  Убрать
                </AppButton>
              </div>
            </div>
          </div>
        </div>
      ) : null}

      <AddStaffModal
        open={addOpen}
        onClose={() => setAddOpen(false)}
        onCreated={() => {
          setError(null);
          void reload({ soft: true });
        }}
      />
    </BookingWorkspaceShell>
  );
}
