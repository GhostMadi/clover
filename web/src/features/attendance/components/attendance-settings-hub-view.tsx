"use client";

import { Clock3, MapPin } from "lucide-react";
import { useCallback, useEffect, useState } from "react";
import { AppButtonLink } from "@/components/shared/app-button";
import { AttendanceListShimmer } from "@/features/attendance/components/attendance-shimmers";
import {
  getAdminWorkplace,
  setDutyOnlyPunch,
} from "@/features/attendance/lib/attendance-api";
import {
  geofenceSubtitle,
  punchTypesSubtitle,
  type AttendanceWorkplace,
} from "@/features/attendance/lib/attendance-model";
import {
  readAttendanceWorkplaceCache,
  writeAttendanceWorkplaceCache,
} from "@/features/attendance/lib/attendance-prefs";
import { AttendanceWorkspaceShell } from "@/features/attendance/components/attendance-workspace-shell";
import {
  ServiceInformer,
  ServiceTile,
} from "@/features/shared/components/service-page";
import { getSessionUserId } from "@/lib/run-service-swr";

export function AttendanceSettingsHubView({
  workplaceId,
}: {
  workplaceId: string;
}) {
  const [loading, setLoading] = useState(true);
  const [workplace, setWorkplace] = useState<AttendanceWorkplace | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [dutyBusy, setDutyBusy] = useState(false);

  const reload = useCallback(async (opts?: { soft?: boolean }) => {
    if (!opts?.soft) setLoading(true);
    setError(null);
    try {
      const uid = await getSessionUserId();
      const w = await getAdminWorkplace(workplaceId);
      setWorkplace(w);
      if (w) writeAttendanceWorkplaceCache(uid, workplaceId, w);
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : "Не удалось загрузить");
    } finally {
      setLoading(false);
    }
  }, [workplaceId]);

  useEffect(() => {
    void (async () => {
      const uid = await getSessionUserId();
      const cached = readAttendanceWorkplaceCache(uid, workplaceId);
      if (cached) {
        setWorkplace(cached);
        setLoading(false);
        await reload({ soft: true });
      } else {
        await reload();
      }
    })();
  }, [reload, workplaceId]);

  const base = `/app/settings/attendance/w/${workplaceId}`;

  if (loading) {
    return (
      <AttendanceWorkspaceShell workplaceId={workplaceId} title="Настройки">
        <div className="px-4 py-5">
          <AttendanceListShimmer rows={4} />
        </div>
      </AttendanceWorkspaceShell>
    );
  }

  if (error || !workplace) {
    return (
      <AttendanceWorkspaceShell workplaceId={workplaceId} title="Настройки">
        <div className="space-y-3 px-4 py-5">
          <p className="text-[14px] text-error">
            {error ?? "Компания не найдена или нет прав admin"}
          </p>
          <AppButtonLink href={base} service="attendance">
            Назад
          </AppButtonLink>
        </div>
      </AttendanceWorkspaceShell>
    );
  }

  return (
    <AttendanceWorkspaceShell
      workplaceId={workplaceId}
      title="Настройки"
      lead="Правила только этой компании. У другой компании — свои."
      companyName={workplace.name}
    >
      <div className="mx-auto max-w-3xl space-y-4">
        <ServiceInformer service="attendance">
          Геозона и типы отметок открываются отдельно. Переключатель дежурства сохраняется сразу.
        </ServiceInformer>

        <div className="grid gap-3">
          <ServiceTile
            service="attendance"
            href={`${base}/settings/geofence`}
            title="Геозона"
            subtitle={geofenceSubtitle(workplace)}
            icon={MapPin}
          />
          <ServiceTile
            service="attendance"
            href={`${base}/settings/punch-types`}
            title="Типы отметок"
            subtitle={punchTypesSubtitle(workplace)}
            icon={Clock3}
          />
        </div>

        <section className="rounded-[16px] border border-line bg-surface p-4">
          <h2 className="text-[15px] font-bold text-ink">Отметка только у дежурного</h2>
          <div className="mt-3">
            <ServiceInformer service="attendance" tone="warning">
              Сохраняется сразу. Когда включено, отметиться может только тот, кто сегодня в очереди.
            </ServiceInformer>
          </div>
          <div className="mt-3 flex items-center justify-between gap-3">
            <p className="text-[13px] text-muted">
              {workplace.dutyOnlyPunch ? "Сейчас включено" : "Сейчас выключено"}
            </p>
            <button
              type="button"
              role="switch"
              aria-checked={workplace.dutyOnlyPunch}
              disabled={dutyBusy}
              onClick={() => {
                const next = !workplace.dutyOnlyPunch;
                setDutyBusy(true);
                void setDutyOnlyPunch({
                  workplaceId,
                  dutyOnlyPunch: next,
                })
                  .then(() =>
                    setWorkplace({ ...workplace, dutyOnlyPunch: next }),
                  )
                  .catch(() => {
                    /* keep previous */
                  })
                  .finally(() => setDutyBusy(false));
              }}
              className={`relative h-7 w-12 shrink-0 rounded-full transition ${
                workplace.dutyOnlyPunch ? "bg-svc-attendance-ink" : "bg-line"
              } disabled:opacity-40`}
            >
              <span
                className={`absolute top-0.5 h-6 w-6 rounded-full bg-surface shadow-elevate-sm transition ${
                  workplace.dutyOnlyPunch ? "left-[1.35rem]" : "left-0.5"
                }`}
              />
            </button>
          </div>
        </section>
      </div>
    </AttendanceWorkspaceShell>
  );
}
