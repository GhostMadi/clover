"use client";

import { useCallback, useEffect, useState } from "react";
import { AppButtonLink } from "@/components/shared/app-button";
import { AttendanceListShimmer } from "@/features/attendance/components/attendance-shimmers";
import {
  buildAnalyticsOverview,
  formatMinutes,
  type AnalyticsOverview,
  type AnalyticsWorker,
} from "@/features/attendance/lib/attendance-analytics";
import {
  getAdminWorkplace,
  listWorkplaceMembers,
  loadAnalyticsOverviewRaw,
  loadProfileLabels,
} from "@/features/attendance/lib/attendance-api";
import {
  monthPeriodToToday,
  type AttendanceWorkplace,
} from "@/features/attendance/lib/attendance-model";
import {
  readAttendanceAnalyticsCache,
  writeAttendanceAnalyticsCache,
} from "@/features/attendance/lib/attendance-prefs";
import { AttendanceWorkspaceShell } from "@/features/attendance/components/attendance-workspace-shell";
import { getSessionUserId } from "@/lib/run-service-swr";

const STATUS_RU: Record<string, string> = {
  full: "Полный",
  late: "Опоздание",
  partial: "Неполный",
  absent: "Пропуск",
  excused: "Отсутствие",
  off: "Выходной",
};

export function AttendanceAnalyticsView({
  workplaceId,
}: {
  workplaceId: string;
}) {
  const back = `/app/settings/attendance/w/${workplaceId}`;
  const period = monthPeriodToToday();
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [workplace, setWorkplace] = useState<AttendanceWorkplace | null>(null);
  const [overview, setOverview] = useState<AnalyticsOverview | null>(null);
  const [selected, setSelected] = useState<AnalyticsWorker | null>(null);

  const reload = useCallback(async (opts?: { soft?: boolean }) => {
    if (!opts?.soft) setLoading(true);
    setError(null);
    try {
      const uid = await getSessionUserId();
      const w = await getAdminWorkplace(workplaceId);
      if (!w) {
        setError("Компания не найдена или нет прав admin");
        return;
      }
      const members = (await listWorkplaceMembers(workplaceId)).filter(
        (m) => m.status === "active",
      );
      const ids = members.map((m) => m.profileId);
      const labels = await loadProfileLabels(ids);
      const raw = await loadAnalyticsOverviewRaw({
        workplaceId,
        start: period.start,
        end: period.end,
      });
      const nextOverview = buildAnalyticsOverview({
        workplace: w,
        workerIds: ids,
        labels,
        punches: raw.punches,
        absences: raw.absences.filter((a) => a.workplaceId === workplaceId),
        start: period.start,
        end: period.end,
      });
      setWorkplace(w);
      setOverview(nextOverview);
      writeAttendanceAnalyticsCache(uid, workplaceId, {
        periodStart: period.start,
        periodEnd: period.end,
        workplace: w,
        overview: nextOverview,
      });
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : "Не удалось загрузить");
    } finally {
      setLoading(false);
    }
  }, [workplaceId, period.start, period.end]);

  useEffect(() => {
    void (async () => {
      const uid = await getSessionUserId();
      const cached = readAttendanceAnalyticsCache(
        uid,
        workplaceId,
        period.start,
        period.end,
      );
      if (cached) {
        setWorkplace(cached.workplace);
        setOverview(cached.overview);
        setLoading(false);
        await reload({ soft: true });
      } else {
        await reload();
      }
    })();
  }, [reload, workplaceId, period.start, period.end]);

  if (loading) {
    return (
      <AttendanceWorkspaceShell workplaceId={workplaceId} title="Аналитика">
        <div className="px-4 py-5">
          <AttendanceListShimmer rows={6} />
        </div>
      </AttendanceWorkspaceShell>
    );
  }

  if (error || !workplace || !overview) {
    return (
      <AttendanceWorkspaceShell workplaceId={workplaceId} title="Аналитика">
        <div className="space-y-3 px-4 py-5">
          <p className="text-[14px] text-error">{error ?? "Нет данных"}</p>
          <AppButtonLink href={back} service="attendance">
            Назад
          </AppButtonLink>
        </div>
      </AttendanceWorkspaceShell>
    );
  }

  if (selected) {
    return (
      <AttendanceWorkspaceShell
        workplaceId={workplaceId}
        title={selected.displayName}
        trailing={
          <button
            type="button"
            onClick={() => setSelected(null)}
            className="px-2 text-[13px] font-bold text-svc-attendance-ink"
          >
            К команде
          </button>
        }
      >
        <div className="space-y-4 px-4 py-5 pb-10">
          <p className="text-[13px] text-muted">
            {formatMinutes(selected.totalMinutes)} · {selected.daysWorked} дн ·
            опозданий {selected.lateDays} · пропусков {selected.missedDays}
          </p>
          <ul className="overflow-hidden rounded-[16px] border border-line bg-surface">
            {selected.days
              .filter((d) => d.status !== "off")
              .map((d, i) => (
                <li
                  key={d.dateKey}
                  className={`flex items-center justify-between gap-3 px-3.5 py-2.5 ${
                    i > 0 ? "border-t border-line" : ""
                  }`}
                >
                  <div>
                    <p className="text-[13px] font-semibold text-ink">
                      {d.dateKey}
                    </p>
                    <p className="text-[11px] text-muted">
                      {STATUS_RU[d.status] ?? d.status}
                      {d.lateMinutes > 0 ? ` · +${d.lateMinutes}м` : ""}
                    </p>
                  </div>
                  <p className="text-[13px] font-bold text-svc-attendance-ink">
                    {d.totalMinutes > 0 ? formatMinutes(d.totalMinutes) : "—"}
                  </p>
                </li>
              ))}
          </ul>
        </div>
      </AttendanceWorkspaceShell>
    );
  }

  return (
    <AttendanceWorkspaceShell workplaceId={workplaceId} title="Аналитика">
      <div className="space-y-5 px-4 py-5 pb-10">
        <div>
          <p className="text-[16px] font-bold text-ink">{period.label}</p>
          <p className="text-[12px] text-muted">
            {period.start} — {period.end}
          </p>
        </div>

        <div className="grid grid-cols-2 gap-2">
          <StatCard
            label="Часы команды"
            value={formatMinutes(overview.totalMinutes)}
          />
          <StatCard
            label="Среднее"
            value={formatMinutes(overview.avgMinutesPerWorker)}
          />
          <StatCard label="Опоздания" value={String(overview.lateDaysTotal)} />
          <StatCard label="Пропуски" value={String(overview.missedDaysTotal)} />
        </div>

        <ul className="overflow-hidden rounded-[16px] border border-line bg-surface">
          {overview.workers.map((w, i) => (
            <li key={w.id} className={i > 0 ? "border-t border-line" : ""}>
              <button
                type="button"
                onClick={() => setSelected(w)}
                className="flex w-full items-center justify-between gap-3 px-3.5 py-3.5 text-left hover:bg-svc-attendance/40"
              >
                <div className="min-w-0">
                  <p className="truncate text-[15px] font-bold text-ink">
                    {w.displayName}
                  </p>
                  <p className="text-[12px] text-muted">
                    {w.daysWorked} дн · опозд. {w.lateDays} · проп. {w.missedDays}
                  </p>
                </div>
                <p className="shrink-0 text-[14px] font-bold text-svc-attendance-ink">
                  {formatMinutes(w.totalMinutes)}
                </p>
              </button>
            </li>
          ))}
        </ul>
      </div>
    </AttendanceWorkspaceShell>
  );
}

function StatCard({ label, value }: { label: string; value: string }) {
  return (
    <div className="rounded-[16px] border border-line bg-surface px-3.5 py-3">
      <p className="text-[11px] font-semibold uppercase tracking-wide text-muted">
        {label}
      </p>
      <p className="mt-1 text-[18px] font-bold text-ink">{value}</p>
    </div>
  );
}
