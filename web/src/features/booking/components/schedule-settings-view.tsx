"use client";

import { useCallback, useEffect, useState } from "react";
import { AppButton } from "@/components/shared/app-button";
import { BookingFormShimmer } from "@/features/booking/components/booking-shimmers";
import { BookingWorkspaceShell } from "@/features/booking/components/booking-workspace-shell";
import {
  createBlockedSlot,
  deleteBlockedSlot,
  getScheduleSettings,
  listBlockedSlots,
  listStaffSchedule,
  saveMyScheduleSettings,
  upsertStaffDay,
  type BookingStaffDaySchedule,
} from "@/features/booking/lib/client-api";
import {
  bookingPointBase,
  readBookingScheduleCache,
  writeBookingScheduleCache,
} from "@/features/booking/lib/booking-prefs";
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
import {
  ServiceEmpty,
  ServiceInformer,
  ServiceSection,
} from "@/features/shared/components/service-page";
import { createClient } from "@/lib/supabase/client";

const WEEKDAYS: { id: number; label: string }[] = [
  { id: 1, label: "Пн" },
  { id: 2, label: "Вт" },
  { id: 3, label: "Ср" },
  { id: 4, label: "Чт" },
  { id: 5, label: "Пт" },
  { id: 6, label: "Сб" },
  { id: 7, label: "Вс" },
];

export function ScheduleSettingsView({ pointId }: { pointId: string }) {
  const [settings, setSettings] = useState<BookingScheduleSettings>(defaultScheduleSettings);
  const [staff, setStaff] = useState<BookingStaff[]>([]);
  const [blocks, setBlocks] = useState<BookingBlockedSlot[]>([]);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [absenceStaffId, setAbsenceStaffId] = useState("");
  const [absenceStart, setAbsenceStart] = useState("");
  const [absenceEnd, setAbsenceEnd] = useState("");
  const [absenceNote, setAbsenceNote] = useState("");
  const [blockStaffId, setBlockStaffId] = useState("");
  const [blockStart, setBlockStart] = useState("");
  const [blockEnd, setBlockEnd] = useState("");
  const [blockReason, setBlockReason] = useState("");
  const [scheduleStaffId, setScheduleStaffId] = useState("");
  const [staffDays, setStaffDays] = useState<BookingStaffDaySchedule[]>([]);
  const [staffScheduleLoading, setStaffScheduleLoading] = useState(false);
  const [staffDayBusy, setStaffDayBusy] = useState<number | null>(null);

  const applyStaffDefaults = (st: BookingStaff[]) => {
    if (!absenceStaffId && st[0]) setAbsenceStaffId(st[0].id);
    if (!blockStaffId && st[0]) setBlockStaffId(st[0].id);
    if (!scheduleStaffId && st[0]) setScheduleStaffId(st[0].id);
  };

  const reload = useCallback(async (opts?: { soft?: boolean }) => {
    if (!opts?.soft) setLoading(true);
    setError(null);
    const from = addDays(startOfLocalDay(), -7);
    const to = addDays(startOfLocalDay(), 60);
    try {
      const {
        data: { session },
      } = await createClient().auth.getSession();
      const uid = session?.user.id ?? null;
      const [s, st, bl] = await Promise.all([
        getScheduleSettings(undefined, pointId),
        listMyStaff(true),
        listBlockedSlots(from, to, pointId),
      ]);
      setSettings(s);
      setStaff(st);
      setBlocks(bl);
      applyStaffDefaults(st);
      writeBookingScheduleCache(uid, pointId, { settings: s, staff: st, blocks: bl });
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : "Ошибка");
    } finally {
      setLoading(false);
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps -- staff defaults only on empty
  }, [pointId]);

  useEffect(() => {
    let cancelled = false;
    void (async () => {
      const {
        data: { session },
      } = await createClient().auth.getSession();
      if (cancelled) return;
      const uid = session?.user.id ?? null;
      const cached = readBookingScheduleCache(uid, pointId);
      if (cached) {
        setSettings(cached.settings);
        setStaff(cached.staff);
        setBlocks(cached.blocks);
        applyStaffDefaults(cached.staff);
        setLoading(false);
        await reload({ soft: true });
      } else {
        await reload();
      }
    })();
    return () => {
      cancelled = true;
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [reload, pointId]);

  useEffect(() => {
    if (!scheduleStaffId) {
      setStaffDays([]);
      return;
    }
    let cancelled = false;
    setStaffScheduleLoading(true);
    void listStaffSchedule(scheduleStaffId)
      .then((days) => {
        if (!cancelled) setStaffDays(days);
      })
      .catch((e: unknown) => {
        if (!cancelled) {
          setError(e instanceof Error ? e.message : "Не удалось загрузить график мастера");
          setStaffDays([]);
        }
      })
      .finally(() => {
        if (!cancelled) setStaffScheduleLoading(false);
      });
    return () => {
      cancelled = true;
    };
  }, [scheduleStaffId]);

  const isStaffDayWorking = (weekday: number): boolean => {
    const row = staffDays.find((d) => d.weekday === weekday);
    return row?.isWorking ?? true;
  };

  const toggleStaffDay = async (weekday: number) => {
    if (!scheduleStaffId || staffDayBusy != null) return;
    const existing = staffDays.find((d) => d.weekday === weekday);
    const nextWorking = !(existing?.isWorking ?? true);
    setStaffDayBusy(weekday);
    setError(null);
    try {
      await upsertStaffDay({
        staffId: scheduleStaffId,
        weekday,
        isWorking: nextWorking,
        workStartHour: nextWorking ? (existing?.workStartHour ?? 9) : null,
        workEndHour: nextWorking ? (existing?.workEndHour ?? 20) : null,
      });
      const days = await listStaffSchedule(scheduleStaffId);
      setStaffDays(days);
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : "Не удалось обновить день");
    } finally {
      setStaffDayBusy(null);
    }
  };

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
      const next = await saveMyScheduleSettings(settings, pointId);
      setSettings(next);
      const {
        data: { session },
      } = await createClient().auth.getSession();
      writeBookingScheduleCache(session?.user.id ?? null, pointId, {
        settings: next,
        staff,
        blocks,
      });
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : "Не удалось сохранить");
    } finally {
      setSaving(false);
    }
  };

  const settingsBase = `${bookingPointBase(pointId)}/settings`;

  return (
    <BookingWorkspaceShell
      pointId={pointId}
      title="Расписание"
      lead="Часы и правила только этой точки. У другой точки — свои."
      backHref={settingsBase}
    >
      <div className="mx-auto max-w-3xl space-y-4">
        {loading ? (
          <BookingFormShimmer />
        ) : (
          <>
            <section className={cardCls}>
              <ServiceSection title="Выходные точки">
                <ServiceInformer service="booking">
                  Дни, когда закрыта вся точка. Тёмный день — выходной, записей нет ни у
                  кого. Светлый — точка открыта. Потом нажмите «Сохранить расписание».
                </ServiceInformer>
              </ServiceSection>
              <div className="flex flex-wrap gap-2">
                {WEEKDAYS.map((d) => {
                  const on = settings.restWeekdays.includes(d.id);
                  return (
                    <button
                      key={d.id}
                      type="button"
                      onClick={() => toggleRest(d.id)}
                      className={`rounded-[12px] px-3 py-2 text-[13px] font-semibold ${
                        on
                          ? "bg-svc-booking-ink text-on-media"
                          : "border border-line bg-bg text-ink"
                      }`}
                    >
                      {d.label}
                      <span className="mt-0.5 block text-[10px] font-bold">
                        {on ? "выходной" : "открыто"}
                      </span>
                    </button>
                  );
                })}
              </div>
            </section>

            <section className={cardCls}>
              <ServiceSection title="Часы работы">
                <ServiceInformer service="booking">
                  С какого времени клиент может прийти и до какого. Вне этого окна слотов
                  нет.
                </ServiceInformer>
              </ServiceSection>
              <div className="grid grid-cols-2 gap-3">
                <label className="block">
                  <span className="mb-1.5 block text-[12px] font-semibold text-muted">
                    Начало дня
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
                  <span className="mb-1.5 block text-[12px] font-semibold text-muted">
                    Конец дня
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
              </div>
            </section>

            <section className={cardCls}>
              <ServiceSection title="Как далеко можно записаться">
                <ServiceInformer service="booking">
                  «На сколько дней» — клиент видит ближайшие дни, окно сдвигается само.
                  «До даты» — запись открыта только до выбранного дня.
                </ServiceInformer>
              </ServiceSection>
              <div className="flex gap-2">
                <button
                  type="button"
                  onClick={() => setSettings((s) => ({ ...s, horizonKind: "days_ahead" }))}
                  className={`rounded-[12px] px-3 py-2 text-[13px] font-semibold ${
                    settings.horizonKind === "days_ahead"
                      ? "bg-svc-booking text-svc-booking-ink"
                      : "border border-line bg-bg text-muted"
                  }`}
                >
                  На сколько дней
                </button>
                <button
                  type="button"
                  onClick={() => setSettings((s) => ({ ...s, horizonKind: "until_date" }))}
                  className={`rounded-[12px] px-3 py-2 text-[13px] font-semibold ${
                    settings.horizonKind === "until_date"
                      ? "bg-svc-booking text-svc-booking-ink"
                      : "border border-line bg-bg text-muted"
                  }`}
                >
                  До даты
                </button>
              </div>
              {settings.horizonKind === "days_ahead" ? (
                <label className="block">
                  <span className="mb-1.5 block text-[12px] font-semibold text-muted">
                    Дней вперёд, от 7 до 90
                  </span>
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
                </label>
              ) : (
                <label className="block">
                  <span className="mb-1.5 block text-[12px] font-semibold text-muted">
                    Последний день записи
                  </span>
                  <input
                    type="date"
                    value={settings.maxBookingUntilDate ?? ""}
                    onChange={(e) =>
                      setSettings((s) => ({ ...s, maxBookingUntilDate: e.target.value || null }))
                    }
                    className={inputCls}
                  />
                </label>
              )}
            </section>

            <section className={cardCls}>
              <ServiceSection title="Отмена и неявка">
                <ServiceInformer service="booking">
                  «Отмена» — за сколько часов до визита клиент ещё может отменить сам.
                  «Не пришёл» — через сколько часов после начала визит закроется сам, если
                  клиент не пришёл.
                </ServiceInformer>
              </ServiceSection>
              <div className="grid grid-cols-2 gap-3">
                <label className="block">
                  <span className="mb-1.5 block text-[12px] font-semibold text-muted">
                    Отмена за, часы
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
                  <span className="mb-1.5 block text-[12px] font-semibold text-muted">
                    Не пришёл через, часы
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
              </div>
            </section>

            <section className={cardCls}>
              <ServiceSection title="Отсутствие мастера">
                <ServiceInformer service="booking">
                  Целые дни, когда мастер не принимает: отпуск, больничный, отъезд. Клиент
                  не увидит его время в эти даты. Добавьте строку и нажмите «Сохранить
                  расписание» ниже.
                </ServiceInformer>
              </ServiceSection>
              {settings.absences.length === 0 ? (
                <ServiceEmpty>Пока нет отсутствий — мастер принимает в свои рабочие дни.</ServiceEmpty>
              ) : (
                <ul className="space-y-1.5">
                  {settings.absences.map((a, i) => (
                    <li
                      key={`${a.staffId}-${a.startDate}-${i}`}
                      className="flex items-center justify-between gap-2 rounded-[12px] border border-line bg-bg px-3 py-2 text-[13px]"
                    >
                      <span>
                        {staff.find((s) => s.id === a.staffId)?.displayName ?? "Мастер"} ·{" "}
                        {a.startDate} — {a.endDate}
                        {a.note?.trim() ? (
                          <span className="mt-0.5 block text-[12px] text-muted">{a.note}</span>
                        ) : null}
                      </span>
                      <button
                        type="button"
                        className="shrink-0 text-[12px] font-bold text-destructive"
                        onClick={() =>
                          setSettings((s) => ({
                            ...s,
                            absences: s.absences.filter((_, idx) => idx !== i),
                          }))
                        }
                      >
                        Убрать
                      </button>
                    </li>
                  ))}
                </ul>
              )}
              <div className="space-y-2">
                <label className="block">
                  <span className="mb-1.5 block text-[12px] font-semibold text-muted">
                    Кто не работает
                  </span>
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
                </label>
                <div className="grid grid-cols-2 gap-2">
                  <label className="block">
                    <span className="mb-1.5 block text-[12px] font-semibold text-muted">
                      С даты
                    </span>
                    <input
                      type="date"
                      value={absenceStart}
                      onChange={(e) => setAbsenceStart(e.target.value)}
                      className={inputCls}
                    />
                  </label>
                  <label className="block">
                    <span className="mb-1.5 block text-[12px] font-semibold text-muted">
                      По дату
                    </span>
                    <input
                      type="date"
                      value={absenceEnd}
                      onChange={(e) => setAbsenceEnd(e.target.value)}
                      className={inputCls}
                    />
                  </label>
                </div>
                <label className="block">
                  <span className="mb-1.5 block text-[12px] font-semibold text-muted">
                    Зачем, для себя
                  </span>
                  <input
                    type="text"
                    value={absenceNote}
                    onChange={(e) => setAbsenceNote(e.target.value)}
                    placeholder="Например, отпуск"
                    className={inputCls}
                  />
                </label>
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
                          note: absenceNote.trim() || null,
                        },
                      ],
                    }));
                    setAbsenceStart("");
                    setAbsenceEnd("");
                    setAbsenceNote("");
                  }}
                >
                  Добавить дни
                </AppButton>
              </div>
            </section>

            {error ? <p className="text-sm text-destructive">{error}</p> : null}
            <div>
              <AppButton service="booking" loading={saving} onClick={() => void save()}>
                Сохранить расписание
              </AppButton>
              <p className="mt-2 text-[12px] text-muted">
                Сохраняет часы точки, выходные и отсутствия. Закрытые часы и дни мастера
                сохраняются своими кнопками.
              </p>
            </div>

            <section className={cardCls}>
              <ServiceSection title="Закрытые часы">
                <ServiceInformer service="booking" tone="next">
                  Не весь день, а кусок времени: обед, своя запись, перерыв. Клиент не
                  сможет выбрать эти часы. Закрытие срабатывает сразу, кнопка «Сохранить
                  расписание» здесь не нужна.
                </ServiceInformer>
              </ServiceSection>
              {blocks.length === 0 ? (
                <ServiceEmpty>Закрытых часов нет — свободно всё рабочее время.</ServiceEmpty>
              ) : (
                <ul className="space-y-1.5">
                  {blocks.map((b) => (
                    <li
                      key={b.id}
                      className="flex items-center justify-between gap-2 rounded-[12px] border border-line bg-bg px-3 py-2 text-[13px]"
                    >
                      <span>
                        {staff.find((s) => s.id === b.staffId)?.displayName ?? "Мастер"} ·{" "}
                        {formatBookingWhen(b.startsAt)} — {formatBookingWhen(b.endsAt)}
                        {b.reason?.trim() ? (
                          <span className="mt-0.5 block text-[12px] text-muted">{b.reason}</span>
                        ) : null}
                      </span>
                      <button
                        type="button"
                        className="shrink-0 text-[12px] font-bold text-destructive"
                        onClick={() => {
                          void deleteBlockedSlot(b.id)
                            .then(() => reload())
                            .catch((e: unknown) =>
                              setError(e instanceof Error ? e.message : "Ошибка"),
                            );
                        }}
                      >
                        Открыть
                      </button>
                    </li>
                  ))}
                </ul>
              )}
              <div className="space-y-2">
                <label className="block">
                  <span className="mb-1.5 block text-[12px] font-semibold text-muted">
                    Чьи часы закрыть
                  </span>
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
                </label>
                <label className="block">
                  <span className="mb-1.5 block text-[12px] font-semibold text-muted">
                    С какого времени
                  </span>
                  <input
                    type="datetime-local"
                    value={blockStart}
                    onChange={(e) => setBlockStart(e.target.value)}
                    className={inputCls}
                  />
                </label>
                <label className="block">
                  <span className="mb-1.5 block text-[12px] font-semibold text-muted">
                    До какого времени
                  </span>
                  <input
                    type="datetime-local"
                    value={blockEnd}
                    onChange={(e) => setBlockEnd(e.target.value)}
                    className={inputCls}
                  />
                </label>
                <label className="block">
                  <span className="mb-1.5 block text-[12px] font-semibold text-muted">
                    Зачем, для себя
                  </span>
                  <input
                    type="text"
                    value={blockReason}
                    onChange={(e) => setBlockReason(e.target.value)}
                    placeholder="Например, обед"
                    className={inputCls}
                  />
                </label>
                <AppButton
                  variant="outline"
                  size="row"
                  disabled={!blockStaffId || !blockStart || !blockEnd}
                  onClick={() => {
                    void createBlockedSlot({
                      pointId,
                      staffId: blockStaffId,
                      startsAt: new Date(blockStart).toISOString(),
                      endsAt: new Date(blockEnd).toISOString(),
                      reason: blockReason.trim() || undefined,
                    })
                      .then(() => {
                        setBlockStart("");
                        setBlockEnd("");
                        setBlockReason("");
                        reload();
                      })
                      .catch((e: unknown) =>
                        setError(e instanceof Error ? e.message : "Ошибка"),
                      );
                  }}
                >
                  Закрыть эти часы
                </AppButton>
              </div>
            </section>

            <section className={cardCls}>
              <ServiceSection title="Дни недели мастера">
                <ServiceInformer service="booking">
                  Обычная неделя этого человека, не отпуск. Жёлтый день — он принимает
                  клиентов. Серый — его выходной, даже если точка в этот день открыта.
                  Нажатие на день сохраняется сразу.
                </ServiceInformer>
              </ServiceSection>
              {staff.length === 0 ? (
                <ServiceEmpty>Сначала добавьте мастеров в разделе «Услуги».</ServiceEmpty>
              ) : (
                <div className="space-y-3">
                  <label className="block">
                    <span className="mb-1.5 block text-[12px] font-semibold text-muted">
                      Чей график
                    </span>
                    <select
                      value={scheduleStaffId}
                      onChange={(e) => setScheduleStaffId(e.target.value)}
                      className={inputCls}
                    >
                      {staff.map((s) => (
                        <option key={s.id} value={s.id}>
                          {s.displayName}
                        </option>
                      ))}
                    </select>
                  </label>
                  {staffScheduleLoading ? (
                    <p className="text-sm text-muted">Загрузка дней…</p>
                  ) : (
                    <div className="flex flex-wrap gap-2">
                      {WEEKDAYS.map((day) => {
                        const on = isStaffDayWorking(day.id);
                        const busy = staffDayBusy === day.id;
                        return (
                          <button
                            key={day.id}
                            type="button"
                            disabled={busy}
                            onClick={() => void toggleStaffDay(day.id)}
                            className={`rounded-[12px] px-3 py-2 text-[13px] font-semibold transition disabled:opacity-50 ${
                              on
                                ? "bg-svc-booking text-svc-booking-ink"
                                : "border border-line bg-bg text-muted"
                            }`}
                          >
                            {day.label}
                            <span className="mt-0.5 block text-[10px] font-bold">
                              {on ? "принимает" : "выходной"}
                            </span>
                          </button>
                        );
                      })}
                    </div>
                  )}
                </div>
              )}
            </section>
          </>
        )}
      </div>
    </BookingWorkspaceShell>
  );
}

const cardCls = "space-y-3 rounded-[16px] border border-line bg-surface p-4";

const inputCls =
  "h-11 w-full rounded-[14px] border border-line bg-bg px-3 text-[14px] text-ink outline-none placeholder:text-muted focus:border-svc-booking-ink/50 [&_option]:bg-surface [&_option]:text-ink";
