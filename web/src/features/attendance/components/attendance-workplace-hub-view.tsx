"use client";

import {
  BarChart3,
  CalendarClock,
  ChevronRight,
  ClipboardList,
  MapPinned,
  Pencil,
  Users,
  Wallet,
} from "lucide-react";
import Link from "next/link";
import { useCallback, useEffect, useState } from "react";
import { AppButtonLink } from "@/components/shared/app-button";
import { AttendanceNameModal } from "@/features/attendance/components/attendance-name-modal";
import { AttendanceListShimmer } from "@/features/attendance/components/attendance-shimmers";
import {
  getAdminWorkplace,
  renameWorkplace,
} from "@/features/attendance/lib/attendance-api";
import type { AttendanceWorkplace } from "@/features/attendance/lib/attendance-model";
import {
  readAttendanceWorkplaceCache,
  writeAttendanceWorkplaceCache,
} from "@/features/attendance/lib/attendance-prefs";
import { SettingsShell } from "@/features/settings/components/settings-shell";
import { serviceTileIcon } from "@/lib/service-accent";
import { getSessionUserId } from "@/lib/run-service-swr";

const SECTIONS = [
  {
    href: "settings",
    label: "Настройки",
    subtitle: "Геозона, типы отметок, дежурства",
    icon: MapPinned,
  },
  {
    href: "members",
    label: "Работники",
    subtitle: "Активные, ожидают, архив",
    icon: Users,
  },
  {
    href: "duty",
    label: "Смены и учёт",
    subtitle: "Сегодня, дежурные, OT, отсутствия",
    icon: CalendarClock,
  },
  {
    href: "timesheet",
    label: "Табель",
    subtitle: "Часы за период и экспорт",
    icon: ClipboardList,
  },
  {
    href: "analytics",
    label: "Аналитика",
    subtitle: "Команда, день, человек",
    icon: BarChart3,
  },
  {
    href: "payroll",
    label: "Зарплата",
    subtitle: "Правила и превью",
    icon: Wallet,
  },
] as const;

export function AttendanceWorkplaceHubView({
  workplaceId,
}: {
  workplaceId: string;
}) {
  const [loading, setLoading] = useState(true);
  const [workplace, setWorkplace] = useState<AttendanceWorkplace | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [renameOpen, setRenameOpen] = useState(false);

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

  if (loading) {
    return (
      <SettingsShell
        title="Компания"
        backHref="/app/settings/attendance"
        service="attendance"
      >
        <div className="px-4 py-5">
          <AttendanceListShimmer rows={6} />
        </div>
      </SettingsShell>
    );
  }

  if (error || !workplace) {
    return (
      <SettingsShell
        title="Компания"
        backHref="/app/settings/attendance"
        service="attendance"
      >
        <div className="space-y-3 px-4 py-5">
          <p className="text-[14px] text-error">
            {error ?? "Компания не найдена или нет прав admin"}
          </p>
          <AppButtonLink href="/app/settings/attendance" service="attendance">
            К хабу
          </AppButtonLink>
        </div>
      </SettingsShell>
    );
  }

  const base = `/app/settings/attendance/w/${workplace.id}`;

  return (
    <SettingsShell
      title={workplace.name}
      backHref="/app/settings/attendance"
      service="attendance"
      trailing={
        <button
          type="button"
          title="Переименовать"
          onClick={() => setRenameOpen(true)}
          className="flex h-10 w-10 items-center justify-center rounded-full text-svc-attendance-ink hover:bg-svc-attendance"
          aria-label="Переименовать"
        >
          <Pencil className="h-4 w-4" strokeWidth={2} />
        </button>
      }
    >
      <div className="space-y-6 px-4 py-5">
        <p className="px-1 text-[13px] text-muted">
          Управление компанией. Punch и GPS — только в мобильном приложении.
        </p>
        <ul className="overflow-hidden rounded-[16px] border border-line bg-surface">
          {SECTIONS.map((item, i) => {
            const Icon = item.icon;
            return (
              <li key={item.href} className={i > 0 ? "border-t border-line" : ""}>
                <Link
                  href={`${base}/${item.href}`}
                  className="flex items-center gap-3 px-3.5 py-3.5 transition hover:bg-svc-attendance/40"
                >
                  <span className={serviceTileIcon("attendance")}>
                    <Icon className="h-5 w-5" strokeWidth={2} />
                  </span>
                  <span className="min-w-0 flex-1">
                    <span className="block text-[15px] font-bold text-ink">
                      {item.label}
                    </span>
                    <span className="block text-[12px] text-muted">
                      {item.subtitle}
                    </span>
                  </span>
                  <ChevronRight className="h-5 w-5 text-muted" strokeWidth={2} />
                </Link>
              </li>
            );
          })}
        </ul>
        {workplace.groupConversationId ? (
          <AppButtonLink
            href={`/app/chat/${workplace.groupConversationId}`}
            service="attendance"
          >
            Чат компании
          </AppButtonLink>
        ) : null}
      </div>

      <AttendanceNameModal
        open={renameOpen}
        title="Переименовать"
        label="Название"
        initialValue={workplace.name}
        submitLabel="Сохранить"
        onClose={() => setRenameOpen(false)}
        onSubmit={async (name) => {
          await renameWorkplace({ workplaceId: workplace.id, name });
          await reload();
        }}
      />
    </SettingsShell>
  );
}
