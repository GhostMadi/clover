"use client";

import { useCallback, useEffect, useState } from "react";
import Link from "next/link";
import { Plus } from "lucide-react";
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
import { createClient } from "@/lib/supabase/client";

export function ServicesListView({ pointId }: { pointId: string }) {
  const [services, setServices] = useState<BookingService[]>([]);
  const [staff, setStaff] = useState<BookingStaff[]>([]);
  const [pending, setPending] = useState<BookingStaffInvite[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [addOpen, setAddOpen] = useState(false);
  const [staffBusyId, setStaffBusyId] = useState<string | null>(null);

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
          listMyStaff(false),
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
        setStaff(cached.staff);
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

  const toggleStaff = async (s: BookingStaff) => {
    if (staffBusyId) return;
    setStaffBusyId(s.id);
    setError(null);
    try {
      await setStaffActive(s.id, !s.isActive);
      await reload({ soft: true });
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : "Не удалось обновить мастера");
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
      <div className="space-y-6 md:grid md:grid-cols-2 md:gap-6 md:space-y-0">
        {error ? (
          <p className="text-sm text-destructive md:col-span-2">{error}</p>
        ) : null}

        <section>
          <p className="mb-2 text-[12px] font-bold uppercase tracking-wide text-muted">
            Каталог
          </p>
          {loading ? (
            <BookingListShimmer rows={4} />
          ) : services.length === 0 ? (
            <div className="rounded-[14px] border border-dashed border-line bg-bg px-3.5 py-5 text-center">
              <p className="text-sm text-muted">Пока нет услуг. Создайте первую.</p>
              <div className="mt-3 flex justify-center">
                <AppButtonLink
                  href={`${bookingPointBase(pointId)}/services/new`}
                  size="row"
                  service="booking"
                >
                  Добавить услугу
                </AppButtonLink>
              </div>
            </div>
          ) : (
            <ul className="overflow-hidden rounded-[16px] border border-line bg-surface">
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
                            неактивна
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

        <section>
          <div className="mb-2 flex items-center justify-between gap-2 px-0.5">
            <p className="text-[12px] font-bold uppercase tracking-wide text-muted">Мастера</p>
            <AppButton size="row" service="booking" onClick={() => setAddOpen(true)}>
              <span className="inline-flex items-center gap-1.5">
                <Plus className="h-4 w-4" strokeWidth={2.5} />
                Добавить
              </span>
            </AppButton>
          </div>
          {loading ? (
            <BookingListShimmer rows={3} />
          ) : (
            <>
              {pending.length > 0 ? (
                <div className="mb-3 space-y-1.5">
                  <p className="text-[11px] font-bold uppercase tracking-wide text-muted">
                    Ожидают
                  </p>
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
                <p className="rounded-[14px] border border-dashed border-line bg-bg px-3.5 py-4 text-sm text-muted">
                  Пока нет мастеров. Добавьте первого.
                </p>
              ) : (
                <ul className="space-y-1.5">
                  {staff.map((s) => (
                    <li
                      key={s.id}
                      className="flex items-center justify-between gap-2 rounded-[12px] border border-line bg-bg px-3 py-2.5"
                    >
                      <span className="min-w-0 truncate text-[14px] font-semibold text-ink">
                        {s.displayName}
                        {!s.isActive ? (
                          <span className="ml-2 text-[11px] font-medium text-muted">выкл</span>
                        ) : null}
                      </span>
                      <button
                        type="button"
                        disabled={staffBusyId === s.id}
                        className="shrink-0 text-[12px] font-bold text-svc-booking-ink disabled:opacity-50"
                        onClick={() => void toggleStaff(s)}
                      >
                        {s.isActive ? "Выкл" : "Вкл"}
                      </button>
                    </li>
                  ))}
                </ul>
              )}
            </>
          )}
        </section>
      </div>

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
