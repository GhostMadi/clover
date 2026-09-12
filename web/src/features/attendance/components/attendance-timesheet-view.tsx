"use client";

import { Download } from "lucide-react";
import { useCallback, useEffect, useState } from "react";
import { AppButton } from "@/components/shared/app-button";
import { AppButtonLink } from "@/components/shared/app-button";
import { AttendanceListShimmer } from "@/features/attendance/components/attendance-shimmers";
import {
  buildAnalyticsOverview,
  formatMinutes,
  type AnalyticsOverview,
} from "@/features/attendance/lib/attendance-analytics";
import {
  downloadTimesheetCsv,
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

export function AttendanceTimesheetView({
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
  const [exporting, setExporting] = useState(false);

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
      <AttendanceWorkspaceShell workplaceId={workplaceId} title="Табель">
        <div className="px-4 py-5">
          <AttendanceListShimmer rows={6} />
        </div>
      </AttendanceWorkspaceShell>
    );
  }

  if (error || !workplace || !overview) {
    return (
      <AttendanceWorkspaceShell workplaceId={workplaceId} title="Табель">
        <div className="space-y-3 px-4 py-5">
          <p className="text-[14px] text-error">{error ?? "Нет данных"}</p>
          <AppButtonLink href={back} service="attendance">
            Назад
          </AppButtonLink>
        </div>
      </AttendanceWorkspaceShell>
    );
  }

  return (
    <AttendanceWorkspaceShell workplaceId={workplaceId} title="Табель">
      <div className="space-y-5 px-4 py-5 pb-10">
        <div className="flex items-start justify-between gap-3">
          <div>
            <p className="text-[16px] font-bold text-ink">{period.label}</p>
            <p className="text-[12px] text-muted">
              {period.start} — {period.end}
            </p>
          </div>
          <AppButton
            type="button"
            size="row"
            service="attendance"
            loading={exporting}
            onClick={() => {
              setExporting(true);
              void downloadTimesheetCsv({
                workplaceId,
                start: period.start,
                end: period.end,
              })
                .then((csv) => {
                  const blob = new Blob([csv], {
                    type: "text/csv;charset=utf-8",
                  });
                  const url = URL.createObjectURL(blob);
                  const a = document.createElement("a");
                  a.href = url;
                  a.download = `timesheet-${workplaceId.slice(0, 8)}.csv`;
                  a.click();
                  URL.revokeObjectURL(url);
                })
                .finally(() => setExporting(false));
            }}
          >
            <Download className="mr-1.5 h-4 w-4" strokeWidth={2} />
            CSV
          </AppButton>
        </div>

        {overview.workers.length === 0 ? (
          <p className="py-8 text-center text-[14px] text-muted">
            Нет активных работников
          </p>
        ) : (
          <ul className="overflow-hidden rounded-[16px] border border-line bg-surface">
            {overview.workers.map((w, i) => (
              <li
                key={w.id}
                className={`flex items-center justify-between gap-3 px-3.5 py-3.5 ${
                  i > 0 ? "border-t border-line" : ""
                }`}
              >
                <div className="min-w-0">
                  <p className="truncate text-[15px] font-bold text-ink">
                    {w.displayName}
                  </p>
                  <p className="text-[12px] text-muted">
                    {w.daysWorked} дн · опозданий {w.lateDays}
                  </p>
                </div>
                <p className="shrink-0 text-[14px] font-bold text-svc-attendance-ink">
                  {formatMinutes(w.totalMinutes)}
                </p>
              </li>
            ))}
          </ul>
        )}
      </div>
    </AttendanceWorkspaceShell>
  );
}
