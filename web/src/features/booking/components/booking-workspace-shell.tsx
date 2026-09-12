"use client";

import {
  BarChart3,
  ClipboardList,
  LayoutGrid,
  MapPin,
  Scissors,
  Settings2,
} from "lucide-react";
import type { ReactNode } from "react";
import { BookingPointSwitcher } from "@/features/booking/components/booking-point-switcher";
import { bookingPointBase } from "@/features/booking/lib/booking-prefs";
import {
  ServiceWorkspaceShell,
  type ServiceWorkspaceNavItem,
} from "@/features/shared/components/service-workspace-shell";

function pointNav(pointId: string): ServiceWorkspaceNavItem[] {
  const base = bookingPointBase(pointId);
  return [
    {
      href: `${base}/inbox`,
      label: "Записи",
      match: (p) => p.startsWith(`${base}/inbox`),
      Icon: ClipboardList,
      group: "main",
    },
    {
      href: base,
      label: "Обзор",
      match: (p) =>
        p === base ||
        p === `${base}/` ||
        p.startsWith(`${base}/guide`),
      Icon: LayoutGrid,
      group: "main",
    },
    {
      href: `${base}/services`,
      label: "Услуги",
      match: (p) => p.startsWith(`${base}/services`),
      Icon: Scissors,
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
      href: "/app/settings/booking/points",
      label: "Точки",
      match: (p) => p.startsWith("/app/settings/booking/points"),
      Icon: MapPin,
      group: "more",
    },
  ];
}

type BookingWorkspaceShellProps = {
  pointId: string;
  title: string;
  children: ReactNode;
  trailing?: ReactNode;
  pointName?: string;
  /** Узкий shell без точек (клиент / calendar) — legacy. */
  hidePointChrome?: boolean;
  backHref?: string;
  hideNav?: boolean;
};

/**
 * Workspace точки записи — тот же каркас, что посещаемость / ресурсы.
 * См. docs/business/website-host-desktop.md
 */
export function BookingWorkspaceShell({
  pointId,
  title,
  children,
  trailing,
  pointName,
  hidePointChrome = false,
  backHref,
  hideNav = false,
}: BookingWorkspaceShellProps) {
  const hubPath = bookingPointBase(pointId);
  const entity = hidePointChrome ? undefined : (
    <BookingPointSwitcher pointId={pointId} currentName={pointName} fullWidth />
  );

  return (
    <ServiceWorkspaceShell
      service="booking"
      brandTitle="Запись"
      brandSubtitle="Точка хозяина"
      title={title}
      nav={hideNav ? [] : pointNav(pointId)}
      hideNav={hideNav}
      hubPath={hubPath}
      hubBackHref="/app/settings/booking/points"
      backHref={backHref ?? `${hubPath}/inbox`}
      entitySlot={entity}
      trailing={trailing}
      maxWidthClassName="max-w-[1400px]"
    >
      {children}
    </ServiceWorkspaceShell>
  );
}

/** Клиентские экраны без точки (my bookings). */
export function BookingClientShell({
  title,
  children,
  backHref = "/app/settings",
}: {
  title: string;
  children: ReactNode;
  backHref?: string;
}) {
  return (
    <ServiceWorkspaceShell
      service="booking"
      brandTitle="Запись"
      title={title}
      nav={[]}
      hideNav
      hubPath="/app/settings/booking/my"
      hubBackHref={backHref}
      backHref={backHref}
      maxWidthClassName="max-w-[720px]"
    >
      {children}
    </ServiceWorkspaceShell>
  );
}
