"use client";

import { ChevronRight, MapPin, Clock3 } from "lucide-react";
import Link from "next/link";
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
import { SettingsShell } from "@/features/settings/components/settings-shell";
import { serviceTileIcon } from "@/lib/service-accent";

export function AttendanceSettingsHubView({
  workplaceId,
}: {
  workplaceId: string;
}) {
  const [loading, setLoading] = useState(true);
  const [workplace, setWorkplace] = useState<AttendanceWorkplace | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [dutyBusy, setDutyBusy] = useState(false);

  const reload = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      setWorkplace(await getAdminWorkplace(workplaceId));
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : "Не удалось загрузить");
    } finally {
      setLoading(false);
    }
  }, [workplaceId]);

  useEffect(() => {
    void reload();
  }, [reload]);

  const base = `/app/settings/attendance/w/${workplaceId}`;

  if (loading) {
    return (
      <SettingsShell title="Настройки" backHref={base} service="attendance">
        <div className="px-4 py-5">
          <AttendanceListShimmer rows={4} />
        </div>
      </SettingsShell>
    );
  }

  if (error || !workplace) {
    return (
      <SettingsShell title="Настройки" backHref={base} service="attendance">
        <div className="space-y-3 px-4 py-5">
          <p className="text-[14px] text-error">
            {error ?? "Компания не найдена или нет прав admin"}
          </p>
          <AppButtonLink href={base} service="attendance">
            Назад
          </AppButtonLink>
        </div>
      </SettingsShell>
    );
  }

  return (
    <SettingsShell title="Настройки" backHref={base} service="attendance">
      <div className="space-y-6 px-4 py-5">
        <div>
          <p className="text-[18px] font-bold text-ink">{workplace.name}</p>
          <p className="mt-1 text-[13px] text-muted">
            Геозона, типы отметок и правило дежурств. Punch — в приложении.
          </p>
        </div>

        <ul className="overflow-hidden rounded-[16px] border border-line bg-surface">
          <li className="border-b border-line">
            <Link
              href={`${base}/settings/geofence`}
              className="flex items-center gap-3 px-3.5 py-3.5 transition hover:bg-svc-attendance/40"
            >
              <span className={serviceTileIcon("attendance")}>
                <MapPin className="h-5 w-5" strokeWidth={2} />
              </span>
              <span className="min-w-0 flex-1">
                <span className="block text-[15px] font-bold text-ink">Геозона</span>
                <span className="block text-[12px] text-muted">
                  {geofenceSubtitle(workplace)}
                </span>
              </span>
              <ChevronRight className="h-5 w-5 text-muted" strokeWidth={2} />
            </Link>
          </li>
          <li>
            <Link
              href={`${base}/settings/punch-types`}
              className="flex items-center gap-3 px-3.5 py-3.5 transition hover:bg-svc-attendance/40"
            >
              <span className={serviceTileIcon("attendance")}>
                <Clock3 className="h-5 w-5" strokeWidth={2} />
              </span>
              <span className="min-w-0 flex-1">
                <span className="block text-[15px] font-bold text-ink">
                  Типы отметок
                </span>
                <span className="block text-[12px] text-muted">
                  {punchTypesSubtitle(workplace)}
                </span>
              </span>
              <ChevronRight className="h-5 w-5 text-muted" strokeWidth={2} />
            </Link>
          </li>
        </ul>

        <div className="rounded-[16px] border border-line bg-surface px-3.5 py-3.5">
          <div className="flex items-start justify-between gap-3">
            <div className="min-w-0 flex-1">
              <p className="text-[15px] font-bold text-ink">
                Отметка только у дежурного
              </p>
              <p className="mt-0.5 text-[12px] text-muted">
                Когда включено, punch разрешён только сегодняшнему дежурному
              </p>
            </div>
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
        </div>
      </div>
    </SettingsShell>
  );
}
