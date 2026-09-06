"use client";

import { useCallback, useEffect, useMemo, useState } from "react";
import { AppButtonLink } from "@/components/shared/app-button";
import { AttendanceListShimmer } from "@/features/attendance/components/attendance-shimmers";
import {
  buildAnalyticsOverview,
  formatMinutes,
  type AnalyticsWorker,
} from "@/features/attendance/lib/attendance-analytics";
import {
  loadWorkerHub,
  payrollPreview,
  type PayrollPreview,
} from "@/features/attendance/lib/attendance-api";
import {
  ABSENCE_KIND_LABEL,
  monthPeriodToToday,
  onDutyFor,
  type AttendanceAbsence,
  type AttendancePunchRecord,
  type AttendanceWorkplace,
} from "@/features/attendance/lib/attendance-model";
import { SettingsShell } from "@/features/settings/components/settings-shell";

const STATUS_RU: Record<string, string> = {
  full: "Полный",
  late: "Опоздание",
  partial: "Неполный",
  absent: "Пропуск",
  excused: "Отсутствие",
  off: "Выходной",
};

export function AttendanceWorkerDetailView({
  workplaceId,
}: {
  workplaceId: string;
}) {
  const back = "/app/attendance";
  const period = monthPeriodToToday();
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [workplace, setWorkplace] = useState<AttendanceWorkplace | null>(null);
  const [worker, setWorker] = useState<AnalyticsWorker | null>(null);
  const [absences, setAbsences] = useState<AttendanceAbsence[]>([]);
  const [punches, setPunches] = useState<AttendancePunchRecord[]>([]);
  const [preview, setPreview] = useState<PayrollPreview["workers"][0] | null>(
    null,
  );
  const [onDuty, setOnDuty] = useState(false);
  const [selectedDay, setSelectedDay] = useState<string | null>(null);
  const [shiftOpen, setShiftOpen] = useState(false);
  const [needsAck, setNeedsAck] = useState(false);

  const reload = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const hub = await loadWorkerHub();
      if (!hub) {
        setError("Нужен вход");
        return;
      }
      const membership = hub.memberships.find(
        (m) => m.workplaceId === workplaceId,
      );
      const w =
        hub.workplaces.find((x) => x.id === workplaceId) ?? null;
      if (!membership || !w) {
        setError("Компания не найдена или нет доступа");
        return;
      }
      const myPunches = hub.punches.filter(
        (p) => p.workplaceId === workplaceId,
      );
      const myAbsences = hub.absences.filter(
        (a) => a.workplaceId === workplaceId,
      );
      const overview = buildAnalyticsOverview({
        workplace: w,
        workerIds: [hub.userId],
        labels: new Map([[hub.userId, { name: "Я", username: "" }]]),
        punches: myPunches.map((p) => ({
          id: p.id,
          profileId: p.profileId,
          punchKind: p.punchKind,
          punchedAt: p.punchedAt,
          cancelled: p.cancelled,
        })),
        absences: myAbsences,
        start: period.start,
        end: period.end,
      });
      setWorkplace(w);
      setWorker(overview.workers[0] ?? null);
      setAbsences(myAbsences);
      setPunches(
        myPunches
          .slice()
          .sort((a, b) => b.punchedAt.getTime() - a.punchedAt.getTime()),
      );
      setOnDuty(onDutyFor(w.dutyRoster, new Date()).includes(hub.userId));
      setShiftOpen(membership.shiftOpen);
      setNeedsAck(membership.needsAck);
      setSelectedDay(period.end);
      try {
        const p = await payrollPreview({
          workplaceId,
          start: period.start,
          end: period.end,
          rules: w.payrollRules,
        });
        setPreview(
          p.workers.find((row) => row.workerId === hub.userId) ?? null,
        );
      } catch {
        setPreview(null);
      }
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : "Не удалось загрузить");
    } finally {
      setLoading(false);
    }
  }, [workplaceId, period.start, period.end]);

  useEffect(() => {
    void reload();
  }, [reload]);

  const dayRecord = useMemo(() => {
    if (!worker || !selectedDay) return null;
    return worker.days.find((d) => d.dateKey === selectedDay) ?? null;
  }, [worker, selectedDay]);

  const dayPunches = useMemo(() => {
    if (!selectedDay) return [];
    return punches.filter((p) => {
      const key = `${p.punchedAt.getFullYear()}-${String(p.punchedAt.getMonth() + 1).padStart(2, "0")}-${String(p.punchedAt.getDate()).padStart(2, "0")}`;
      return key === selectedDay;
    });
  }, [punches, selectedDay]);

  if (loading) {
    return (
      <SettingsShell title="Мои детали" backHref={back} service="attendance">
        <div className="px-4 py-5">
          <AttendanceListShimmer rows={6} />
        </div>
      </SettingsShell>
    );
  }

  if (error || !workplace || !worker) {
    return (
      <SettingsShell title="Мои детали" backHref={back} service="attendance">
        <div className="space-y-3 px-4 py-5">
          <p className="text-[14px] text-error">{error ?? "Нет данных"}</p>
          <AppButtonLink href={back} service="attendance">
            Назад
          </AppButtonLink>
        </div>
      </SettingsShell>
    );
  }

  return (
    <SettingsShell
      title={workplace.name}
      backHref={back}
      service="attendance"
    >
      <div className="space-y-5 px-4 py-5 pb-10">
        <div className="rounded-[16px] border border-svc-attendance-ink/30 bg-svc-attendance/50 px-3.5 py-3.5">
          <p className="text-[13px] font-semibold text-svc-attendance-ink">
            Только просмотр · отмечайтесь в приложении
          </p>
          <p className="mt-1 text-[12px] text-muted">
            {shiftOpen ? "Смена открыта" : "Смена закрыта"}
            {onDuty ? " · сегодня дежурство" : ""}
          </p>
          {needsAck ? (
            <p className="mt-1 text-[12px] font-semibold text-error">
              Примите обновлённые правила в чате компании
            </p>
          ) : null}
        </div>

        <div>
          <p className="text-[16px] font-bold text-ink">{period.label}</p>
          <div className="mt-2 grid grid-cols-2 gap-2">
            <Metric label="Часы" value={formatMinutes(worker.totalMinutes)} />
            <Metric label="Смены" value={String(worker.daysWorked)} />
            <Metric label="Опоздания" value={String(worker.lateDays)} />
            <Metric label="Пропуски" value={String(worker.missedDays)} />
          </div>
        </div>

        {preview ? (
          <section className="rounded-[16px] border border-line bg-surface px-3.5 py-3.5">
            <p className="text-[12px] font-bold uppercase tracking-wide text-muted">
              Превью ЗП
            </p>
            <p className="mt-1 text-[18px] font-bold text-svc-attendance-ink">
              {Math.round(preview.netPay).toLocaleString("ru-RU")} ₸
            </p>
            <p className="text-[12px] text-muted">
              база {Math.round(preview.baseSalary).toLocaleString("ru-RU")} ₸
            </p>
            {preview.lines.length > 0 ? (
              <ul className="mt-2 space-y-1">
                {preview.lines.slice(0, 6).map((l, i) => (
                  <li key={i} className="flex justify-between gap-2 text-[12px]">
                    <span className="text-muted">{l.label}</span>
                    <span className="font-semibold text-ink">
                      {l.amount > 0 ? "+" : ""}
                      {Math.round(l.amount).toLocaleString("ru-RU")} ₸
                    </span>
                  </li>
                ))}
              </ul>
            ) : null}
          </section>
        ) : null}

        <section className="space-y-2">
          <p className="text-[15px] font-bold text-ink">Дни месяца</p>
          <ul className="overflow-hidden rounded-[16px] border border-line bg-surface">
            {worker.days
              .filter((d) => d.status !== "off")
              .map((d, i) => (
                <li key={d.dateKey} className={i > 0 ? "border-t border-line" : ""}>
                  <button
                    type="button"
                    onClick={() => setSelectedDay(d.dateKey)}
                    className={`flex w-full items-center justify-between gap-3 px-3.5 py-2.5 text-left ${
                      selectedDay === d.dateKey ? "bg-svc-attendance/40" : ""
                    }`}
                  >
                    <div>
                      <p className="text-[13px] font-semibold text-ink">
                        {d.dateKey}
                      </p>
                      <p className="text-[11px] text-muted">
                        {STATUS_RU[d.status] ?? d.status}
                      </p>
                    </div>
                    <p className="text-[13px] font-bold text-svc-attendance-ink">
                      {d.totalMinutes > 0 ? formatMinutes(d.totalMinutes) : "—"}
                    </p>
                  </button>
                </li>
              ))}
          </ul>
          {dayRecord ? (
            <div className="rounded-[16px] border border-line bg-surface px-3.5 py-3">
              <p className="text-[13px] font-bold text-ink">
                {selectedDay} · {STATUS_RU[dayRecord.status]}
              </p>
              {dayPunches.length === 0 ? (
                <p className="mt-1 text-[12px] text-muted">Нет отметок за день</p>
              ) : (
                <ul className="mt-2 space-y-1">
                  {dayPunches.map((p) => (
                    <li key={p.id} className="text-[12px] text-muted">
                      {p.punchedAt.toLocaleTimeString("ru-RU", {
                        hour: "2-digit",
                        minute: "2-digit",
                      })}{" "}
                      · {p.label}
                      {p.cancelled ? " (отменено)" : ""}
                    </li>
                  ))}
                </ul>
              )}
            </div>
          ) : null}
        </section>

        <section className="space-y-2">
          <p className="text-[15px] font-bold text-ink">Отсутствия</p>
          {absences.length === 0 ? (
            <p className="text-[13px] text-muted">Нет оформленных отсутствий</p>
          ) : (
            <ul className="overflow-hidden rounded-[16px] border border-line bg-surface">
              {absences.map((a, i) => (
                <li
                  key={a.id}
                  className={`px-3.5 py-3 ${i > 0 ? "border-t border-line" : ""}`}
                >
                  <p className="text-[14px] font-semibold text-ink">
                    {ABSENCE_KIND_LABEL[a.kind] ?? a.kind}
                  </p>
                  <p className="text-[12px] text-muted">
                    {a.startDate}
                    {a.endDate !== a.startDate ? ` — ${a.endDate}` : ""}
                  </p>
                </li>
              ))}
            </ul>
          )}
        </section>

        <section className="space-y-2">
          <p className="text-[15px] font-bold text-ink">История отметок</p>
          {punches.length === 0 ? (
            <p className="text-[13px] text-muted">Пока нет отметок</p>
          ) : (
            <ul className="overflow-hidden rounded-[16px] border border-line bg-surface">
              {punches.slice(0, 20).map((p, i) => (
                <li
                  key={p.id}
                  className={`px-3.5 py-3 ${i > 0 ? "border-t border-line" : ""}`}
                >
                  <p className="text-[14px] font-semibold text-ink">
                    {p.label}
                    {p.cancelled ? " · отменено" : ""}
                  </p>
                  <p className="text-[12px] text-muted">
                    {p.punchedAt.toLocaleString("ru-RU")}
                  </p>
                </li>
              ))}
            </ul>
          )}
        </section>

        {workplace.groupConversationId ? (
          <AppButtonLink
            href={`/app/chat/${workplace.groupConversationId}`}
            service="attendance"
          >
            Чат компании
          </AppButtonLink>
        ) : null}
      </div>
    </SettingsShell>
  );
}

function Metric({ label, value }: { label: string; value: string }) {
  return (
    <div className="rounded-[16px] border border-line bg-surface px-3.5 py-3">
      <p className="text-[11px] font-semibold text-muted">{label}</p>
      <p className="mt-1 text-[16px] font-bold text-ink">{value}</p>
    </div>
  );
}
