"use client";

import { ChevronRight, MessageCircle } from "lucide-react";
import Link from "next/link";
import { useCallback, useEffect, useState } from "react";
import { AppButtonLink } from "@/components/shared/app-button";
import { AttendanceListShimmer } from "@/features/attendance/components/attendance-shimmers";
import {
  buildAnalyticsOverview,
  formatMinutes,
} from "@/features/attendance/lib/attendance-analytics";
import {
  loadWorkerHub,
  type WorkerHubData,
} from "@/features/attendance/lib/attendance-api";
import {
  monthPeriodToToday,
  onDutyFor,
  type AttendanceMembershipLite,
  type AttendanceWorkplace,
} from "@/features/attendance/lib/attendance-model";
import { SettingsShell } from "@/features/settings/components/settings-shell";
import { serviceTileIcon } from "@/lib/service-accent";
import { Building2 } from "lucide-react";

export function AttendanceWorkerHubView() {
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [data, setData] = useState<WorkerHubData | null>(null);

  const reload = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      setData(await loadWorkerHub());
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : "Не удалось загрузить");
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    void reload();
  }, [reload]);

  if (loading) {
    return (
      <SettingsShell title="Моя посещаемость" service="attendance">
        <div className="px-4 py-5">
          <AttendanceListShimmer rows={4} />
        </div>
      </SettingsShell>
    );
  }

  if (error) {
    return (
      <SettingsShell title="Моя посещаемость" service="attendance">
        <div className="space-y-3 px-4 py-5">
          <p className="text-[14px] text-error">{error}</p>
          <AppButtonLink href="/app/settings" service="attendance">
            В настройки
          </AppButtonLink>
        </div>
      </SettingsShell>
    );
  }

  const memberships = (data?.memberships ?? []).filter(
    (m) => m.status === "active" || m.status === "pending" || m.status === "accepted",
  );

  return (
    <SettingsShell title="Моя посещаемость" service="attendance">
      <div className="space-y-5 px-4 py-5 pb-10">
        <div className="rounded-[16px] border border-svc-attendance-ink/30 bg-svc-attendance/50 px-3.5 py-3.5">
          <p className="text-[14px] font-semibold text-svc-attendance-ink">
            Отмечайтесь в приложении
          </p>
          <p className="mt-1 text-[12px] text-muted">
            Punch и GPS — только на телефоне. Здесь можно смотреть часы, историю
            и детали смены.
          </p>
        </div>

        {memberships.length === 0 ? (
          <p className="py-10 text-center text-[14px] text-muted">
            Нет активных компаний. Примите приглашение в чате.
          </p>
        ) : (
          <ul className="space-y-3">
            {memberships.map((m) => {
              const workplace =
                data?.workplaces.find((w) => w.id === m.workplaceId) ?? null;
              return (
                <WorkerCompanyCard
                  key={m.id}
                  membership={m}
                  workplace={workplace}
                  punches={
                    data?.punches.filter((p) => p.workplaceId === m.workplaceId) ??
                    []
                  }
                  absences={
                    data?.absences.filter(
                      (a) => a.workplaceId === m.workplaceId,
                    ) ?? []
                  }
                  userId={data!.userId}
                />
              );
            })}
          </ul>
        )}

        <AppButtonLink href="/app/settings/attendance" variant="outline">
          Управление компаниями (admin)
        </AppButtonLink>
      </div>
    </SettingsShell>
  );
}

function WorkerCompanyCard({
  membership,
  workplace,
  punches,
  absences,
  userId,
}: {
  membership: AttendanceMembershipLite;
  workplace: AttendanceWorkplace | null;
  punches: WorkerHubData["punches"];
  absences: WorkerHubData["absences"];
  userId: string;
}) {
  const period = monthPeriodToToday();
  const onDuty =
    workplace &&
    onDutyFor(workplace.dutyRoster, new Date()).includes(userId);
  const lastPunch = punches
    .filter((p) => !p.cancelled)
    .sort((a, b) => b.punchedAt.getTime() - a.punchedAt.getTime())[0];

  let miniHours = "—";
  if (workplace) {
    const overview = buildAnalyticsOverview({
      workplace,
      workerIds: [userId],
      labels: new Map([
        [userId, { name: "Я", username: "" }],
      ]),
      punches: punches.map((p) => ({
        id: p.id,
        profileId: p.profileId,
        punchKind: p.punchKind,
        punchedAt: p.punchedAt,
        cancelled: p.cancelled,
      })),
      absences,
      start: period.start,
      end: period.end,
    });
    const me = overview.workers[0];
    if (me) {
      miniHours = `${formatMinutes(me.totalMinutes)} · ${me.daysWorked} смен`;
    }
  }

  const pending = membership.status === "pending";

  return (
    <li className="overflow-hidden rounded-[16px] border border-line bg-surface">
      <Link
        href={`/app/attendance/w/${membership.workplaceId}`}
        className="block px-3.5 py-3.5 transition hover:bg-svc-attendance/30"
      >
        <div className="flex items-start gap-3">
          <span className={serviceTileIcon("attendance")}>
            <Building2 className="h-5 w-5" strokeWidth={2} />
          </span>
          <div className="min-w-0 flex-1">
            <p className="truncate text-[15px] font-bold text-ink">
              {membership.workplaceName}
            </p>
            <p className="mt-0.5 text-[12px] text-muted">
              {pending
                ? "Ожидает принятия в чате"
                : membership.shiftOpen
                  ? "Смена открыта"
                  : "Смена закрыта"}
              {lastPunch
                ? ` · ${lastPunch.label} ${lastPunch.punchedAt.toLocaleTimeString("ru-RU", { hour: "2-digit", minute: "2-digit" })}`
                : ""}
            </p>
            {!pending ? (
              <p className="mt-1 text-[12px] font-semibold text-svc-attendance-ink">
                {miniHours}
              </p>
            ) : null}
            {onDuty ? (
              <p className="mt-1 text-[11px] font-bold text-svc-attendance-ink">
                Сегодня вы дежурите
              </p>
            ) : null}
            {membership.needsAck ? (
              <p className="mt-1 text-[11px] font-semibold text-error">
                Нужно принять правила v{membership.configVersion} в чате
              </p>
            ) : null}
          </div>
          <ChevronRight className="mt-1 h-5 w-5 shrink-0 text-muted" />
        </div>
        <p className="mt-2 text-[12px] font-bold text-svc-attendance-ink">
          Мои детали →
        </p>
      </Link>
      {workplace?.groupConversationId ? (
        <Link
          href={`/app/chat/${workplace.groupConversationId}`}
          className="flex items-center gap-2 border-t border-line px-3.5 py-2.5 text-[12px] font-semibold text-muted hover:bg-bg"
        >
          <MessageCircle className="h-4 w-4" strokeWidth={2} />
          Чат компании
        </Link>
      ) : null}
    </li>
  );
}
