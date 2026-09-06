"use client";

import { useCallback, useEffect, useMemo, useState } from "react";
import { AppButton } from "@/components/shared/app-button";
import { AppButtonLink } from "@/components/shared/app-button";
import { AttendanceListShimmer } from "@/features/attendance/components/attendance-shimmers";
import {
  fetchBootstrap,
  getAdminWorkplace,
  loadProfileLabels,
  setOvertimeStatus,
  updateDutyRoster,
  upsertAbsence,
} from "@/features/attendance/lib/attendance-api";
import {
  ABSENCE_KIND_LABEL,
  WEEKDAY_SHORT,
  onDutyFor,
  type AttendanceAbsence,
  type AttendanceDutyRoster,
  type AttendanceOvertime,
  type AttendanceWorkplace,
} from "@/features/attendance/lib/attendance-model";
import { SettingsShell } from "@/features/settings/components/settings-shell";

type ActiveMember = { id: string; name: string };

export function AttendanceDutyView({ workplaceId }: { workplaceId: string }) {
  const back = `/app/settings/attendance/w/${workplaceId}`;
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [workplace, setWorkplace] = useState<AttendanceWorkplace | null>(null);
  const [members, setMembers] = useState<ActiveMember[]>([]);
  const [absences, setAbsences] = useState<AttendanceAbsence[]>([]);
  const [overtime, setOvertime] = useState<AttendanceOvertime[]>([]);
  const [roster, setRoster] = useState<AttendanceDutyRoster | null>(null);
  const [labels, setLabels] = useState<Map<string, { name: string; username: string }>>(
    new Map(),
  );
  const [savingRoster, setSavingRoster] = useState(false);
  const [otBusy, setOtBusy] = useState<string | null>(null);
  const [absenceOpen, setAbsenceOpen] = useState(false);
  const [absProfile, setAbsProfile] = useState("");
  const [absKind, setAbsKind] = useState("day_off");
  const [absStart, setAbsStart] = useState("");
  const [absEnd, setAbsEnd] = useState("");
  const [absBusy, setAbsBusy] = useState(false);
  const [absError, setAbsError] = useState<string | null>(null);

  const reload = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const w = await getAdminWorkplace(workplaceId);
      if (!w) {
        setError("Компания не найдена или нет прав admin");
        return;
      }
      const boot = await fetchBootstrap();
      const active = boot.memberships.filter(
        (m) => m.workplaceId === workplaceId && m.status === "active",
      );
      const ids = active.map((m) => m.profileId);
      const lab = await loadProfileLabels(ids);
      setLabels(lab);
      setMembers(
        active.map((m) => ({
          id: m.profileId,
          name: lab.get(m.profileId)?.name ?? m.profileId.slice(0, 8),
        })),
      );
      setWorkplace(w);
      setRoster(w.dutyRoster);
      setAbsences(boot.absences.filter((a) => a.workplaceId === workplaceId));
      setOvertime(
        boot.overtimeEntries.filter((o) => o.workplaceId === workplaceId),
      );
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : "Не удалось загрузить");
    } finally {
      setLoading(false);
    }
  }, [workplaceId]);

  useEffect(() => {
    void reload();
  }, [reload]);

  const todayOnDuty = useMemo(() => {
    if (!roster) return [];
    return onDutyFor(roster, new Date());
  }, [roster]);

  const pendingOt = overtime.filter((o) => o.status === "pending");
  const decidedOt = overtime.filter((o) => o.status !== "pending").slice(0, 12);

  if (loading) {
    return (
      <SettingsShell title="Смены и учёт" backHref={back} service="attendance">
        <div className="px-4 py-5">
          <AttendanceListShimmer rows={6} />
        </div>
      </SettingsShell>
    );
  }

  if (error || !workplace || !roster) {
    return (
      <SettingsShell title="Смены и учёт" backHref={back} service="attendance">
        <div className="space-y-3 px-4 py-5">
          <p className="text-[14px] text-error">{error ?? "Нет данных"}</p>
          <AppButtonLink href={back} service="attendance">
            Назад
          </AppButtonLink>
        </div>
      </SettingsShell>
    );
  }

  const toggleWorker = (id: string) => {
    setRoster((prev) => {
      if (!prev) return prev;
      const has = prev.workerIds.includes(id);
      return {
        ...prev,
        workerIds: has
          ? prev.workerIds.filter((x) => x !== id)
          : [...prev.workerIds, id],
      };
    });
  };

  const toggleWeekday = (d: number) => {
    setRoster((prev) => {
      if (!prev) return prev;
      const has = prev.workingWeekdays.includes(d);
      const next = has
        ? prev.workingWeekdays.filter((x) => x !== d)
        : [...prev.workingWeekdays, d];
      return {
        ...prev,
        workingWeekdays: next.length > 0 ? next : [1, 2, 3, 4, 5],
      };
    });
  };

  const saveRoster = async () => {
    setSavingRoster(true);
    try {
      await updateDutyRoster({ workplaceId, roster });
      await reload();
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : "Не удалось сохранить очередь");
    } finally {
      setSavingRoster(false);
    }
  };

  return (
    <SettingsShell title="Смены и учёт" backHref={back} service="attendance">
      <div className="space-y-6 px-4 py-5 pb-10">
        <section className="rounded-[16px] border border-line bg-surface px-3.5 py-3.5">
          <p className="text-[12px] font-bold uppercase tracking-wide text-muted">
            Сегодня дежурит
          </p>
          {todayOnDuty.length === 0 ? (
            <p className="mt-2 text-[14px] text-muted">
              Никого — настройте очередь ниже
            </p>
          ) : (
            <ul className="mt-2 space-y-1">
              {todayOnDuty.map((id) => (
                <li key={id} className="text-[15px] font-bold text-ink">
                  {labels.get(id)?.name ?? id.slice(0, 8)}
                </li>
              ))}
            </ul>
          )}
          {workplace.dutyOnlyPunch ? (
            <p className="mt-2 text-[12px] text-svc-attendance-ink">
              Включён режим «отметка только у дежурного»
            </p>
          ) : null}
        </section>

        <section className="space-y-3">
          <p className="text-[15px] font-bold text-ink">Очередь дежурных</p>
          <div className="overflow-hidden rounded-[16px] border border-line bg-surface">
            {members.length === 0 ? (
              <p className="px-3.5 py-4 text-[13px] text-muted">
                Нет активных работников
              </p>
            ) : (
              members.map((m, i) => {
                const on = roster.workerIds.includes(m.id);
                return (
                  <button
                    key={m.id}
                    type="button"
                    onClick={() => toggleWorker(m.id)}
                    className={`flex w-full items-center justify-between px-3.5 py-3 text-left ${
                      i > 0 ? "border-t border-line" : ""
                    } hover:bg-svc-attendance/30`}
                  >
                    <span className="text-[14px] font-semibold text-ink">{m.name}</span>
                    <span
                      className={`text-[12px] font-bold ${
                        on ? "text-svc-attendance-ink" : "text-muted"
                      }`}
                    >
                      {on ? "В очереди" : "Добавить"}
                    </span>
                  </button>
                );
              })
            )}
          </div>

          <p className="text-[13px] font-semibold text-ink">Рабочие дни</p>
          <div className="flex flex-wrap gap-2">
            {[1, 2, 3, 4, 5, 6, 7].map((d) => {
              const on = roster.workingWeekdays.includes(d);
              return (
                <button
                  key={d}
                  type="button"
                  onClick={() => toggleWeekday(d)}
                  className={`rounded-full px-3 py-1.5 text-[12px] font-bold ${
                    on
                      ? "bg-svc-attendance text-svc-attendance-ink"
                      : "bg-bg text-muted"
                  }`}
                >
                  {WEEKDAY_SHORT[d]}
                </button>
              );
            })}
          </div>

          <label className="block">
            <span className="mb-1 block text-[12px] font-semibold text-muted">
              Старт очереди (необязательно)
            </span>
            <input
              type="date"
              value={roster.startDate ?? ""}
              onChange={(e) =>
                setRoster({ ...roster, startDate: e.target.value || null })
              }
              className="h-11 w-full rounded-[14px] border border-line bg-bg px-3 text-[15px] text-ink outline-none focus:border-svc-attendance-ink/50"
            />
          </label>

          <AppButton
            type="button"
            service="attendance"
            loading={savingRoster}
            onClick={() => void saveRoster()}
          >
            Сохранить очередь
          </AppButton>
        </section>

        <section className="space-y-3">
          <div className="flex items-center justify-between gap-2">
            <p className="text-[15px] font-bold text-ink">Отсутствия</p>
            <button
              type="button"
              onClick={() => {
                setAbsProfile(members[0]?.id ?? "");
                setAbsKind("day_off");
                setAbsStart("");
                setAbsEnd("");
                setAbsError(null);
                setAbsenceOpen((v) => !v);
              }}
              className="text-[12px] font-bold text-svc-attendance-ink"
            >
              {absenceOpen ? "Скрыть" : "+ Добавить"}
            </button>
          </div>

          {absenceOpen ? (
            <div className="space-y-3 rounded-[16px] border border-line bg-surface p-3.5">
              <label className="block">
                <span className="mb-1 block text-[12px] font-semibold text-muted">
                  Работник
                </span>
                <select
                  value={absProfile}
                  onChange={(e) => setAbsProfile(e.target.value)}
                  className="h-11 w-full rounded-[14px] border border-line bg-bg px-3 text-[15px] text-ink"
                >
                  {members.map((m) => (
                    <option key={m.id} value={m.id}>
                      {m.name}
                    </option>
                  ))}
                </select>
              </label>
              <label className="block">
                <span className="mb-1 block text-[12px] font-semibold text-muted">
                  Тип
                </span>
                <select
                  value={absKind}
                  onChange={(e) => setAbsKind(e.target.value)}
                  className="h-11 w-full rounded-[14px] border border-line bg-bg px-3 text-[15px] text-ink"
                >
                  {Object.entries(ABSENCE_KIND_LABEL).map(([k, v]) => (
                    <option key={k} value={k}>
                      {v}
                    </option>
                  ))}
                </select>
              </label>
              <div className="grid grid-cols-2 gap-2">
                <label className="block">
                  <span className="mb-1 block text-[12px] font-semibold text-muted">
                    С
                  </span>
                  <input
                    type="date"
                    value={absStart}
                    onChange={(e) => setAbsStart(e.target.value)}
                    className="h-11 w-full rounded-[14px] border border-line bg-bg px-3 text-[15px] text-ink"
                  />
                </label>
                <label className="block">
                  <span className="mb-1 block text-[12px] font-semibold text-muted">
                    По
                  </span>
                  <input
                    type="date"
                    value={absEnd}
                    onChange={(e) => setAbsEnd(e.target.value)}
                    className="h-11 w-full rounded-[14px] border border-line bg-bg px-3 text-[15px] text-ink"
                  />
                </label>
              </div>
              {absError ? (
                <p className="text-[13px] text-error">{absError}</p>
              ) : null}
              <AppButton
                type="button"
                service="attendance"
                loading={absBusy}
                disabled={!absProfile || !absStart || !absEnd}
                onClick={() => {
                  setAbsBusy(true);
                  setAbsError(null);
                  void upsertAbsence({
                    workplaceId,
                    profileId: absProfile,
                    kind: absKind,
                    startDate: absStart,
                    endDate: absEnd,
                  })
                    .then(() => {
                      setAbsenceOpen(false);
                      return reload();
                    })
                    .catch((e: unknown) => {
                      setAbsError(
                        e instanceof Error ? e.message : "Не удалось сохранить",
                      );
                    })
                    .finally(() => setAbsBusy(false));
                }}
              >
                Сохранить отсутствие
              </AppButton>
            </div>
          ) : null}

          {absences.length === 0 ? (
            <p className="text-[13px] text-muted">Пока нет записей</p>
          ) : (
            <ul className="overflow-hidden rounded-[16px] border border-line bg-surface">
              {absences.slice(0, 20).map((a, i) => (
                <li
                  key={a.id}
                  className={`px-3.5 py-3 ${i > 0 ? "border-t border-line" : ""}`}
                >
                  <p className="text-[14px] font-bold text-ink">
                    {labels.get(a.profileId)?.name ?? a.profileId.slice(0, 8)}
                  </p>
                  <p className="text-[12px] text-muted">
                    {ABSENCE_KIND_LABEL[a.kind] ?? a.kind} · {a.startDate}
                    {a.endDate !== a.startDate ? ` — ${a.endDate}` : ""}
                  </p>
                </li>
              ))}
            </ul>
          )}
        </section>

        <section className="space-y-3">
          <p className="text-[15px] font-bold text-ink">
            Переработка · ожидают {pendingOt.length}
          </p>
          {pendingOt.length === 0 ? (
            <p className="text-[13px] text-muted">Нет заявок на approve</p>
          ) : (
            <ul className="overflow-hidden rounded-[16px] border border-line bg-surface">
              {pendingOt.map((o, i) => (
                <li
                  key={o.id}
                  className={`space-y-2 px-3.5 py-3 ${i > 0 ? "border-t border-line" : ""}`}
                >
                  <p className="text-[14px] font-bold text-ink">
                    {labels.get(o.profileId)?.name ?? o.profileId.slice(0, 8)}
                  </p>
                  <p className="text-[12px] text-muted">
                    {o.workDate} · {o.hours} ч
                  </p>
                  <div className="flex gap-2">
                    <button
                      type="button"
                      disabled={otBusy === o.id}
                      onClick={() => {
                        setOtBusy(o.id);
                        void setOvertimeStatus({
                          entryId: o.id,
                          status: "approved",
                        })
                          .then(() => reload())
                          .finally(() => setOtBusy(null));
                      }}
                      className="rounded-full bg-svc-attendance px-3 py-1.5 text-[12px] font-bold text-svc-attendance-ink disabled:opacity-40"
                    >
                      Approve
                    </button>
                    <button
                      type="button"
                      disabled={otBusy === o.id}
                      onClick={() => {
                        setOtBusy(o.id);
                        void setOvertimeStatus({
                          entryId: o.id,
                          status: "rejected",
                        })
                          .then(() => reload())
                          .finally(() => setOtBusy(null));
                      }}
                      className="rounded-full bg-bg px-3 py-1.5 text-[12px] font-bold text-error disabled:opacity-40"
                    >
                      Reject
                    </button>
                  </div>
                </li>
              ))}
            </ul>
          )}

          {decidedOt.length > 0 ? (
            <ul className="overflow-hidden rounded-[16px] border border-line bg-surface">
              {decidedOt.map((o, i) => (
                <li
                  key={o.id}
                  className={`px-3.5 py-3 ${i > 0 ? "border-t border-line" : ""}`}
                >
                  <p className="text-[14px] font-semibold text-ink">
                    {labels.get(o.profileId)?.name ?? o.profileId.slice(0, 8)}
                  </p>
                  <p className="text-[12px] text-muted">
                    {o.workDate} · {o.hours} ч · {o.status}
                  </p>
                </li>
              ))}
            </ul>
          ) : null}
        </section>
      </div>
    </SettingsShell>
  );
}
