"use client";

import { useEffect, useMemo, useState } from "react";
import { useRouter } from "next/navigation";
import { AppButton } from "@/components/shared/app-button";
import { SettingsShell } from "@/features/settings/components/settings-shell";
import {
  BookingCatalogShimmer,
  BookingSlotsShimmer,
} from "@/features/booking/components/booking-shimmers";
import {
  createBooking,
  getBookingAvailability,
  getMyBonusBalanceAtHost,
} from "@/features/booking/lib/client-api";
import { listHostCatalog } from "@/features/booking/lib/services-api";
import type {
  BookingCatalogItem,
  BookingSlot,
  BookingStaff,
} from "@/features/booking/lib/booking-model";
import {
  addDays,
  dateKeyLocal,
  formatPriceKzt,
  formatSlotTime,
  startOfLocalDay,
} from "@/features/booking/lib/booking-format";

type Props = {
  hostId: string;
  hostName: string;
  presetServiceId?: string | null;
};

export function ClientBookFlow({ hostId, hostName, presetServiceId }: Props) {
  const router = useRouter();
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [catalog, setCatalog] = useState<BookingCatalogItem[]>([]);
  const [serviceId, setServiceId] = useState<string | null>(presetServiceId ?? null);
  const [staffId, setStaffId] = useState<string | null>(null);
  const [day, setDay] = useState(() => startOfLocalDay());
  const [slots, setSlots] = useState<BookingSlot[]>([]);
  const [dayReason, setDayReason] = useState<string | null>(null);
  const [slotsLoading, setSlotsLoading] = useState(false);
  const [slotStart, setSlotStart] = useState<string | null>(null);
  const [notes, setNotes] = useState("");
  const [useBonuses, setUseBonuses] = useState(true);
  const [bonusBalance, setBonusBalance] = useState(0);
  const [submitting, setSubmitting] = useState(false);

  const selected = useMemo(
    () => catalog.find((c) => c.service.id === serviceId) ?? null,
    [catalog, serviceId],
  );
  const staffOptions: BookingStaff[] = selected?.staff ?? [];

  useEffect(() => {
    let cancelled = false;
    setLoading(true);
    setError(null);
    void Promise.all([listHostCatalog(hostId), getMyBonusBalanceAtHost(hostId)])
      .then(([items, balance]) => {
        if (cancelled) return;
        setCatalog(items);
        setBonusBalance(balance);
        const preset =
          (presetServiceId && items.find((i) => i.service.id === presetServiceId)) ||
          items[0] ||
          null;
        if (preset) {
          setServiceId(preset.service.id);
          const staff =
            preset.staff.length === 1
              ? preset.staff[0]
              : preset.staff.find((s) => s.id === preset.service.defaultStaffId) ??
                preset.staff[0];
          setStaffId(staff?.id ?? null);
        }
      })
      .catch((e: unknown) => {
        if (!cancelled) setError(e instanceof Error ? e.message : "Не удалось загрузить услуги");
      })
      .finally(() => {
        if (!cancelled) setLoading(false);
      });
    return () => {
      cancelled = true;
    };
  }, [hostId, presetServiceId]);

  useEffect(() => {
    if (!serviceId || !staffId) {
      setSlots([]);
      setDayReason(null);
      return;
    }
    let cancelled = false;
    setSlotsLoading(true);
    setSlotStart(null);
    void getBookingAvailability({ hostId, serviceId, staffId, day })
      .then((res) => {
        if (cancelled) return;
        setSlots(res.slots);
        setDayReason(res.dayUnavailableReason);
      })
      .catch((e: unknown) => {
        if (!cancelled) {
          setSlots([]);
          setDayReason(e instanceof Error ? e.message : "Нет слотов");
        }
      })
      .finally(() => {
        if (!cancelled) setSlotsLoading(false);
      });
    return () => {
      cancelled = true;
    };
  }, [hostId, serviceId, staffId, day]);

  const days = useMemo(() => {
    const base = startOfLocalDay();
    return Array.from({ length: 14 }, (_, i) => addDays(base, i));
  }, []);

  const bonusSpend = useMemo(() => {
    if (!selected || !useBonuses || selected.service.bonusPayPercent <= 0) return 0;
    const cap = Math.floor((selected.service.price * selected.service.bonusPayPercent) / 100);
    return Math.min(bonusBalance, cap);
  }, [selected, useBonuses, bonusBalance]);

  const onConfirm = async () => {
    if (!serviceId || !staffId || !slotStart || submitting) return;
    setSubmitting(true);
    setError(null);
    try {
      await createBooking({
        hostId,
        serviceId,
        staffId,
        startsAt: slotStart,
        clientNotes: notes,
        useBonuses,
      });
      router.push("/app/settings/booking/my");
      router.refresh();
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : "Не удалось создать запись");
      setSubmitting(false);
    }
  };

  return (
    <SettingsShell title="Запись" backHref={`/app/u/${hostId}`} service="booking">
      <div className="space-y-5 px-4 py-5">
        <div>
          <p className="text-[13px] font-semibold text-muted">К хозяину</p>
          <p className="text-[17px] font-bold text-ink">{hostName}</p>
        </div>

        {loading ? (
          <BookingCatalogShimmer />
        ) : catalog.length === 0 ? (
          <p className="text-sm text-muted">Пока нет активных услуг для записи.</p>
        ) : (
          <>
            <section>
              <p className="mb-2 text-[12px] font-bold uppercase tracking-wide text-muted">
                Услуга
              </p>
              <div className="space-y-2">
                {catalog.map(({ service }) => {
                  const active = service.id === serviceId;
                  return (
                    <button
                      key={service.id}
                      type="button"
                      onClick={() => {
                        setServiceId(service.id);
                        const staff =
                          service.staff.length === 1
                            ? service.staff[0]
                            : service.staff.find((s) => s.id === service.defaultStaffId) ??
                              service.staff[0];
                        setStaffId(staff?.id ?? null);
                        setSlotStart(null);
                      }}
                      className={`flex w-full items-start gap-3 rounded-[16px] border px-3.5 py-3 text-left transition ${
                        active
                          ? "border-svc-booking-ink/50 bg-svc-booking"
                          : "border-line bg-surface hover:bg-surface-muted"
                      }`}
                    >
                      <span className="text-xl">{service.emojiText}</span>
                      <span className="min-w-0 flex-1">
                        <span className="block text-[15px] font-bold text-ink">{service.title}</span>
                        <span className="block text-[12px] text-muted">
                          {service.durationMinutes} мин · {formatPriceKzt(service.price)}
                        </span>
                      </span>
                    </button>
                  );
                })}
              </div>
            </section>

            {staffOptions.length > 0 ? (
              <section>
                <p className="mb-2 text-[12px] font-bold uppercase tracking-wide text-muted">
                  Мастер
                </p>
                <div className="flex flex-wrap gap-2">
                  {staffOptions.map((s) => {
                    const active = s.id === staffId;
                    return (
                      <button
                        key={s.id}
                        type="button"
                        onClick={() => {
                          setStaffId(s.id);
                          setSlotStart(null);
                        }}
                        className={`rounded-full px-3.5 py-2 text-[13px] font-semibold transition ${
                          active
                            ? "bg-svc-booking-ink text-on-media"
                            : "border border-line bg-surface text-ink hover:bg-surface-muted"
                        }`}
                      >
                        {s.displayName}
                      </button>
                    );
                  })}
                </div>
              </section>
            ) : null}

            <section>
              <p className="mb-2 text-[12px] font-bold uppercase tracking-wide text-muted">День</p>
              <div className="flex gap-2 overflow-x-auto pb-1">
                {days.map((d) => {
                  const key = dateKeyLocal(d);
                  const active = dateKeyLocal(day) === key;
                  const label = d.toLocaleDateString("ru-RU", {
                    weekday: "short",
                    day: "numeric",
                    month: "short",
                  });
                  return (
                    <button
                      key={key}
                      type="button"
                      onClick={() => setDay(d)}
                      className={`shrink-0 rounded-[14px] px-3 py-2 text-[12px] font-semibold capitalize transition ${
                        active
                          ? "bg-svc-booking text-svc-booking-ink"
                          : "border border-line bg-surface text-ink"
                      }`}
                    >
                      {label}
                    </button>
                  );
                })}
              </div>
            </section>

            <section>
              <p className="mb-2 text-[12px] font-bold uppercase tracking-wide text-muted">Время</p>
              {slotsLoading ? (
                <BookingSlotsShimmer />
              ) : dayReason ? (
                <p className="text-sm text-muted">{dayReason}</p>
              ) : slots.length === 0 ? (
                <p className="text-sm text-muted">На этот день нет свободных слотов.</p>
              ) : (
                <div className="flex flex-wrap gap-2">
                  {slots.map((slot) => {
                    const busy = slot.status === "my_conflict" || slot.status === "host_busy";
                    const active = slot.startsAt === slotStart;
                    return (
                      <button
                        key={slot.startsAt}
                        type="button"
                        disabled={busy}
                        title={slot.conflictLabel ?? undefined}
                        onClick={() => setSlotStart(slot.startsAt)}
                        className={`rounded-[12px] px-3 py-2 text-[13px] font-semibold transition disabled:cursor-not-allowed disabled:opacity-40 ${
                          active
                            ? "bg-svc-booking-ink text-on-media"
                            : "border border-line bg-surface text-ink hover:bg-svc-booking/50"
                        }`}
                      >
                        {formatSlotTime(slot.startsAt)}
                      </button>
                    );
                  })}
                </div>
              )}
            </section>

            {selected && selected.service.bonusPayPercent > 0 && bonusBalance > 0 ? (
              <label className="flex items-center justify-between gap-3 rounded-[16px] border border-line bg-surface px-3.5 py-3">
                <span className="text-[14px] font-semibold text-ink">
                  Списать бонусы
                  <span className="mt-0.5 block text-[12px] font-medium text-muted">
                    Баланс {bonusBalance} · до {bonusSpend}
                  </span>
                </span>
                <input
                  type="checkbox"
                  checked={useBonuses}
                  onChange={(e) => setUseBonuses(e.target.checked)}
                  className="h-5 w-5 accent-[var(--svc-booking-ink)]"
                />
              </label>
            ) : null}

            <label className="block">
              <span className="mb-2 block text-[12px] font-bold uppercase tracking-wide text-muted">
                Комментарий
              </span>
              <input
                value={notes}
                onChange={(e) => setNotes(e.target.value.slice(0, 300))}
                placeholder="По желанию"
                className="h-12 w-full rounded-[14px] border border-line bg-bg px-4 text-[15px] text-ink outline-none placeholder:text-muted focus:border-svc-booking-ink/50"
              />
            </label>

            {error ? <p className="text-sm text-destructive">{error}</p> : null}

            <AppButton
              service="booking"
              loading={submitting}
              disabled={!slotStart || !serviceId || !staffId}
              onClick={() => void onConfirm()}
            >
              Записаться
            </AppButton>
          </>
        )}
      </div>
    </SettingsShell>
  );
}
