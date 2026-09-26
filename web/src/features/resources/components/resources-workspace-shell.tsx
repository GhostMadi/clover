"use client";

import {
  BookOpen,
  LayoutGrid,
  MapPin,
  SlidersHorizontal,
} from "lucide-react";
import type { ReactNode } from "react";
import {
  ServiceWorkspaceShell,
  type ServiceWorkspaceNavItem,
} from "@/features/shared/components/service-workspace-shell";

const BASE = "/app/settings/resources";

const NAV: ServiceWorkspaceNavItem[] = [
  {
    href: BASE,
    label: "Обзор",
    match: (p) => p === BASE || p === `${BASE}/`,
    Icon: LayoutGrid,
    group: "main",
  },
  {
    href: `${BASE}/locations`,
    label: "Местоположения",
    match: (p) => p.startsWith(`${BASE}/locations`),
    Icon: MapPin,
    group: "main",
  },
  {
    href: `${BASE}/filters`,
    label: "Фильтры",
    match: (p) => p.startsWith(`${BASE}/filters`),
    Icon: SlidersHorizontal,
    group: "main",
  },
  {
    href: `${BASE}/guide/overview`,
    label: "Гайд",
    match: (p) => p.startsWith(`${BASE}/guide`),
    Icon: BookOpen,
    group: "main",
  },
];

type ResourcesWorkspaceShellProps = {
  title: string;
  lead?: string;
  children: ReactNode;
  trailing?: ReactNode;
  backHref?: string;
};

/** Workspace «Ресурсы» — тот же каркас, что Запись / Посещаемость. */
export function ResourcesWorkspaceShell({
  title,
  lead,
  children,
  trailing,
  backHref = BASE,
}: ResourcesWorkspaceShellProps) {
  return (
    <ServiceWorkspaceShell
      service="resources"
      brandTitle="Ресурсы"
      brandSubtitle="Справочник витрины"
      title={title}
      lead={lead}
      nav={NAV}
      hubPath={BASE}
      backHref={backHref}
      trailing={trailing}
      maxWidthClassName="max-w-[1400px]"
    >
      {children}
    </ServiceWorkspaceShell>
  );
}
