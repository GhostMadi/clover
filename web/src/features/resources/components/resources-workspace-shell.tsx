"use client";

import {
  LayoutGrid,
  MapPin,
  SlidersHorizontal,
} from "lucide-react";
import type { ReactNode } from "react";
import {
  ServiceWorkspaceShell,
  type ServiceWorkspaceNavItem,
} from "@/features/shared/components/service-workspace-shell";

const NAV: ServiceWorkspaceNavItem[] = [
  {
    href: "/app/settings/resources",
    label: "Обзор",
    match: (p) =>
      p === "/app/settings/resources" ||
      p.startsWith("/app/settings/resources/guide"),
    Icon: LayoutGrid,
    group: "main",
  },
  {
    href: "/app/settings/resources/locations",
    label: "Локации",
    match: (p) => p.startsWith("/app/settings/resources/locations"),
    Icon: MapPin,
    group: "main",
  },
  {
    href: "/app/settings/resources/filters",
    label: "Фильтры",
    match: (p) => p.startsWith("/app/settings/resources/filters"),
    Icon: SlidersHorizontal,
    group: "main",
  },
];

type ResourcesWorkspaceShellProps = {
  title: string;
  children: ReactNode;
  trailing?: ReactNode;
  backHref?: string;
};

/** Workspace «Ресурсы» — тот же каркас, что Запись / Посещаемость. */
export function ResourcesWorkspaceShell({
  title,
  children,
  trailing,
  backHref = "/app/settings/resources",
}: ResourcesWorkspaceShellProps) {
  return (
    <ServiceWorkspaceShell
      service="resources"
      brandTitle="Ресурсы"
      brandSubtitle="Справочник хозяина"
      title={title}
      nav={NAV}
      hubPath="/app/settings/resources"
      backHref={backHref}
      trailing={trailing}
      maxWidthClassName="max-w-[1400px]"
    >
      {children}
    </ServiceWorkspaceShell>
  );
}
