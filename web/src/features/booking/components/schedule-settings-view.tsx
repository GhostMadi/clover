"use client";

import { useEffect, useState } from "react";
import { AppButton } from "@/components/shared/app-button";
import { BookingFormShimmer } from "@/features/booking/components/booking-shimmers";
import { BookingWorkspaceShell } from "@/features/booking/components/booking-workspace-shell";
import {
  createBlockedSlot,
  deleteBlockedSlot,
  getScheduleSettings,
  listBlockedSlots,
  saveMyScheduleSettings,
} from "@/features/booking/lib/client-api";
import { listMyStaff } from "@/features/booking/lib/staff-api";
import {
  defaultScheduleSettings,
  type BookingBlockedSlot,
  type BookingScheduleSettings,
  type BookingStaff,
} from "@/features/booking/lib/booking-model";
import {
  addDays,
  formatBookingWhen,
  startOfLocalDay,
} from "@/features/booking/lib/booking-format";

const WEEKDAYS: { id: number; label: string }[] = [
  { id: 1, label: "Пн" },
  { id: 2, label: "Вт" },
  { id: 3, label: "Ср" },
  { id: 4, label: "Чт" },
  { id: 5, label: "Пт" },
  { id: 6, label: "Сб" },
  { id: 7, label: "Вс" },
];

export function ScheduleSettingsView() {
  const [settings, setSettings] = useState<BookingScheduleSettings>(defaultScheduleSettings);
  const [staff, setStaff] = useState<BookingStaff[]>([]);
  const [blocks, setBlocks] = useState<BookingBlockedSlot[]>([]);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [absenceStaffId, setAbsenceStaffId] = useState("");
  const [absenceStart, setAbsenceStart] = useState("");
  const [absenceEnd, setAbsenceEnd] = useState("");
  const [blockStaffId, setBlockStaffId] = useState("");
  const [blockStart, setBlockStart] = useState("");
  const [blockEnd, setBlockEnd] = useState("");

  const reload = () => {
    setLoading(true);
    const from = addDays(startOfLocalDay(), -7);
    const to = addDays(startOfLocalDay(), 60);
    void Promise.all([getScheduleSettings(), listMyStaff(true), listBlockedSlots(from, to)])
      .then(([s, st, bl]) => {
        setSettings(s);
        setStaff(st);
        setBlocks(bl);
        if (!absenceStaffId && st[0]) setAbsenceStaffId(st[0].id);
        if (!blockStaffId && st[0]) setBlockStaffId(st[0].id);
      })
      .catch((e: unknown) => setError(e instanceof Error ? e.message : "Ошибка"))
      .finally(() => setLoading(false));
  };

  useEffect(() => {
    reload();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const toggleRest = (day: number) => {
    setSettings((s) => ({
      ...s,
      restWeekdays: s.restWeekdays.includes(day)
        ? s.restWeekdays.filter((d) => d !== day)
        : [...s.restWeekdays, day].sort(),
    }));
  };

  const save = async () => {
    setSaving(true);
    setError(null);
    try {
      const next = await saveMyScheduleSettings(settings);
      setSettings(next);
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : "Не удалось сохранить");
    } finally {
      setSaving(false);
    }
  };

  return (
    <BookingWorkspaceShell title="Расписание">
      <div className="mx-auto max-w-3xl space-y-6">
        {loading ? (
          <BookingFormShimmer />
        ) : (
          <>
            <section>
              <p className="mb-2 text-[12px] font-bold uppercase tracking-wide text-muted">
                Выходные
              </p>
              <div className="flex flex-wrap gap-2">
                {WEEKDAYS.map((d) => {
                  const on = settings.restWeekdays.includes(d.id);
                  return (
                    <button
                      key={d.id}
                      type="button"
                      onClick={() => toggleRest(d.id)}
                      className={`rounded-full px-3 py-1.5 text-[13px] font-semibold ${
                        on
                          ? "bg-svc-booking-ink text-on-media"
                          : "border border-line bg-surface"
                      }`}
                    >
                      {d.label}
                    </button>
                  );
                })}
              </div>
            </section>

            <section className="grid grid-cols-2 gap-3">
              <label className="block">
                <span className="mb-1.5 block text-[12px] font-bold uppercase text-muted">
                  Начало
                </span>
                <input
                  type="time"
                  value={settings.workStart.slice(0, 5)}
                  onChange={(e) =>
                    setSettings((s) => ({ ...s, workStart: `${e.target.value}:00` }))
                  }
                  className={inputCls}
                />
              </label>
              <label className="block">
                <span className="mb-1.5 block text-[12px] font-bold uppercase text-muted">
                  Конец
                </span>
                <input
                  type="time"
                  value={settings.workEnd.slice(0, 5)}
                  onChange={(e) =>
                    setSettings((s) => ({ ...s, workEnd: `${e.target.value}:00` }))
                  }
                  className={inputCls}
                />
              </label>
            </section>

            <section>
              <p className="mb-2 text-[12px] font-bold uppercase tracking-wide text-muted">
                Горизонт
              </p>
              <div className="mb-3 flex gap-2">
                <button
                  type="button"
                  onClick={() => setSettings((s) => ({ ...s, horizonKind: "days_ahead" }))}
                  className={`rounded-full px-3 py-1.5 text-[13px] font-semibold ${
                    settings.horizonKind === "days_ahead"
                      ? "bg-svc-booking text-svc-booking-ink"
                      : "border border-line"
                  }`}
                >
                  На N дней
                </button>
                <button
                  type="button"
                  onClick={() => setSettings((s) => ({ ...s, horizonKind: "until_date" }))}
                  className={`rounded-full px-3 py-1.5 text-[13px] font-semibold ${
                    settings.horizonKind === "until_date"
                      ? "bg-svc-booking text-svc-booking-ink"
                      : "border border-line"
                  }`}
                >
                  До даты
                </button>
              </div>
              {settings.horizonKind === "days_ahead" ? (
                <input
                  type="number"
                  min={7}
                  max={90}
                  value={settings.maxBookingDaysAhead}
                  onChange={(e) =>
                    setSettings((s) => ({
                      ...s,
                      maxBookingDaysAhead: Number(e.target.value) || 14,
                    }))
                  }
                  className={inputCls}
                />
              ) : (
                <input
                  type="date"
                  value={settings.maxBookingUntilDate ?? ""}
                  onChange={(e) =>
                    setSettings((s) => ({ ...s, maxBookingUntilDate: e.target.value || null }))
                  }
                  className={inputCls}
                />
              )}
            </section>

            <section className="grid grid-cols-2 gap-3">
              <label className="block">
                <span className="mb-1.5 block text-[12px] font-bold uppercase text-muted">
                  Отмена за, ч
                </span>
                <input
                  type="number"
                  min={0}
                  value={settings.clientCancelHoursBefore}
                  onChange={(e) =>
                    setSettings((s) => ({
                      ...s,
                      clientCancelHoursBefore: Number(e.target.value) || 0,
                    }))
                  }
                  className={inputCls}
                />
              </label>
              <label className="block">
                <span className="mb-1.5 block text-[12px] font-bold uppercase text-muted">
                  Авто «не пришёл», ч
                </span>
                <input
                  type="number"
                  min={0}
                  value={settings.autoCloseHoursAfterVisit}
                  onChange={(e) =>
                    setSettings((s) => ({
                      ...s,
                      autoCloseHoursAfterVisit: Number(e.target.value) || 0,
                    }))
                  }
                  className={inputCls}
                />
              </label>
            </section>

            <section>
              <p className="mb-2 text-[12px] font-bold uppercase tracking-wide text-muted">
                Отсутствия мастеров
              </p>
              <ul className="mb-3 space-y-1.5">
                {settings.absences.map((a, i) => (
                  <li
                    key={`${a.staffId}-${a.startDate}-${i}`}
                    className="flex items-center justify-between gap-2 rounded-[12px] border border-line bg-surface px-3 py-2 text-[13px]"
                  >
                    <span>
                      {staff.find((s) => s.id === a.staffId)?.displayName ?? "Мастер"} ·{" "}
                      {a.startDate} — {a.endDate}
                    </span>
                    <button
                      type="button"
                      className="text-destructive font-semibold"
                      onClick={() =>
                        setSettings((s) => ({
                          ...s,
                          absences: s.absences.filter((_, idx) => idx !== i),
                        }))
                      }
                    >
                      ×
                    </button>
                  </li>
                ))}
              </ul>
              <div className="space-y-2">
                <select
                  value={absenceStaffId}
                  onChange={(e) => setAbsenceStaffId(e.target.value)}
                  className={inputCls}
                >
                  {staff.map((s) => (
                    <option key={s.id} value={s.id}>
                      {s.displayName}
                    </option>
                  ))}
                </select>
                <div className="grid grid-cols-2 gap-2">
                  <input
                    type="date"
                    value={absenceStart}
                    onChange={(e) => setAbsenceStart(e.target.value)}
                    className={inputCls}
                  />
                  <input
                    type="date"
                    value={absenceEnd}
                    onChange={(e) => setAbsenceEnd(e.target.value)}
                    className={inputCls}
                  />
                </div>
                <AppButton
                  variant="outline"
                  size="row"
                  disabled={!absenceStaffId || !absenceStart || !absenceEnd}
                  onClick={() => {
                    setSettings((s) => ({
                      ...s,
                      absences: [
                        ...s.absences,
                        {
                          id: "",
                          staffId: absenceStaffId,
                          startDate: absenceStart,
                          endDate: absenceEnd,
                          note: null,
                        },
                      ],
                    }));
                    setAbsenceStart("");
                    setAbsenceEnd("");
                  }}
                >
                  Добавить отсутствие
                </AppButton>
              </div>
            </section>

            {error ? <p className="text-sm text-destructive">{error}</p> : null}
            <AppButton service="booking" loading={saving} onClick={() => void save()}>
              Сохранить расписание
            </AppButton>

            <section>
              <p className="mb-2 text-[12px] font-bold uppercase tracking-wide text-muted">
                Блокировки слотов
              </p>
              <ul className="mb-3 space-y-1.5">
                {blocks.map((b) => (
                  <li
                    key={b.id}
                    className="flex items-center justify-between gap-2 rounded-[12px] border border-line bg-surface px-3 py-2 text-[13px]"
                  >
                    <span>
                      {staff.find((s) => s.id === b.staffId)?.displayName ?? "Мастер"} ·{" "}
                      {formatBookingWhen(b.startsAt)} → {formatBookingWhen(b.endsAt)}
                    </span>
                    <button
                      type="button"
                      className="font-semibold text-destructive"
                      onClick={() => {
                        void deleteBlockedSlot(b.id)
                          .then(reload)
                          .catch((e: unknown) =>
                            setError(e instanceof Error ? e.message : "Ошибка"),
                          );
                      }}
                    >
                      ×
                    </button>
                  </li>
                ))}
              </ul>
              <div className="space-y-2">
                <select
                  value={blockStaffId}
                  onChange={(e) => setBlockStaffId(e.target.value)}
                  className={inputCls}
                >
                  {staff.map((s) => (
                    <option key={s.id} value={s.id}>
                      {s.displayName}
                    </option>
                  ))}
                </select>
                <input
                  type="datetime-local"
                  value={blockStart}
                  onChange={(e) => setBlockStart(e.target.value)}
                  className={inputCls}
                />
                <input
                  type="datetime-local"
                  value={blockEnd}
                  onChange={(e) => setBlockEnd(e.target.value)}
                  className={inputCls}
                />
                <AppButton
                  variant="outline"
                  size="row"
                  disabled={!blockStaffId || !blockStart || !blockEnd}
                  onClick={() => {
                    void createBlockedSlot({
                      staffId: blockStaffId,
                      startsAt: new Date(blockStart).toISOString(),
                      endsAt: new Date(blockEnd).toISOString(),
                    })
                      .then(() => {
                        setBlockStart("");
                        setBlockEnd("");
                        reload();
                      })
                      .catch((e: unknown) =>
                        setError(e instanceof Error ? e.message : "Ошибка"),
                      );
                  }}
                >
                  Заблокировать
                </AppButton>
              </div>
            </section>
          </>
        )}
      </div>
    </BookingWorkspaceShell>
  );
}

const inputCls =
  "h-11 w-full rounded-[14px] border border-line bg-bg px-3 text-[14px] text-ink outline-none placeholder:text-muted focus:border-svc-booking-ink/50 [&_option]:bg-surface [&_option]:text-ink";
