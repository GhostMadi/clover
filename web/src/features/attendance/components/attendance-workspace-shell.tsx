"use client";

import {
  BarChart3,
  Building2,
  CalendarClock,
  ClipboardList,
  LayoutGrid,
  Settings2,
  Users,
  Wallet,
} from "lucide-react";
import type { ReactNode } from "react";
import { AttendanceCompanySwitcher } from "@/features/attendance/components/attendance-company-switcher";
import {
  ServiceWorkspaceShell,
  type ServiceWorkspaceNavItem,
} from "@/features/shared/components/service-workspace-shell";

function workplaceNav(workplaceId: string): ServiceWorkspaceNavItem[] {
  const base = `/app/settings/attendance/w/${workplaceId}`;
  return [
    {
      href: base,
      label: "Сегодня",
      match: (p) => p === base || p === `${base}/`,
      Icon: LayoutGrid,
      group: "main",
    },
    {
      href: `${base}/members`,
      label: "Люди",
      match: (p) => p.startsWith(`${base}/members`),
      Icon: Users,
      group: "main",
    },
    {
      href: `${base}/duty`,
      label: "Дежурства",
      match: (p) => p.startsWith(`${base}/duty`),
      Icon: CalendarClock,
      group: "main",
    },
    {
      href: `${base}/timesheet`,
      label: "Табель",
      match: (p) => p.startsWith(`${base}/timesheet`),
      Icon: ClipboardList,
      group: "main",
    },
    {
      href: `${base}/payroll`,
      label: "ЗП",
      match: (p) => p.startsWith(`${base}/payroll`),
      Icon: Wallet,
      group: "main",
    },
    {
      href: `${base}/analytics`,
      label: "Аналитика",
      match: (p) => p.startsWith(`${base}/analytics`),
      Icon: BarChart3,
      group: "main",
    },
    {
      href: `${base}/settings`,
      label: "Настройки",
      match: (p) => p.startsWith(`${base}/settings`),
      Icon: Settings2,
      group: "more",
    },
    {
      href: "/app/settings/attendance/companies",
      label: "Компании",
      match: (p) =>
        p === "/app/settings/attendance/companies" ||
        p.startsWith("/app/settings/attendance/companies/"),
      Icon: Building2,
      group: "more",
    },
  ];
}

type AttendanceWorkspaceShellProps = {
  workplaceId: string;
  title: string;
  children: ReactNode;
  trailing?: ReactNode;
  brandSubtitle?: string;
  /** Имя компании для селектора (если title — другой экран). */
  companyName?: string;
};

/**
 * Workspace компании — тот же каркас, что Запись / Ресурсы.
 * См. docs/business/website-host-desktop.md
 */
export function AttendanceWorkspaceShell({
  workplaceId,
  title,
  children,
  trailing,
  brandSubtitle = "Компания хозяина",
  companyName,
}: AttendanceWorkspaceShellProps) {
  const hubPath = `/app/settings/attendance/w/${workplaceId}`;

  return (
    <ServiceWorkspaceShell
      service="attendance"
      brandTitle="Посещаемость"
      brandSubtitle={brandSubtitle}
      title={title}
      nav={workplaceNav(workplaceId)}
      hubPath={hubPath}
      hubBackHref="/app/settings/attendance/companies"
      backHref={hubPath}
      entitySlot={
        <AttendanceCompanySwitcher
          workplaceId={workplaceId}
          currentName={companyName ?? (title !== "Сегодня" ? title : undefined)}
          fullWidth
        />
      }
      trailing={trailing}
      maxWidthClassName="max-w-[1400px]"
    >
      {children}
    </ServiceWorkspaceShell>
  );
}
