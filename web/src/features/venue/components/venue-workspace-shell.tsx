"use client";

import {
  CalendarClock,
  Eye,
  Inbox,
  LayoutGrid,
  Layers,
  Ticket,
} from "lucide-react";
import type { ReactNode } from "react";
import {
  ServiceWorkspaceShell,
  type ServiceWorkspaceNavItem,
} from "@/features/shared/components/service-workspace-shell";

function venueNav(venueId: string): ServiceWorkspaceNavItem[] {
  const base = `/app/settings/venue/v/${venueId}`;
  return [
    {
      href: base,
      label: "Обзор",
      match: (p) => p === base || p === `${base}/`,
      Icon: LayoutGrid,
      group: "main",
    },
    {
      href: `${base}/bookables`,
      label: "Bookable",
      match: (p) => p.startsWith(`${base}/bookables`),
      Icon: Ticket,
      group: "main",
    },
    {
      href: `${base}/sessions`,
      label: "Occasion",
      match: (p) => p.startsWith(`${base}/sessions`),
      Icon: CalendarClock,
      group: "main",
    },
    {
      href: `${base}/plan`,
      label: "План",
      match: (p) => p.startsWith(`${base}/plan`),
      Icon: Layers,
      group: "main",
    },
    {
      href: `${base}/showcase`,
      label: "Витрина",
      match: (p) => p.startsWith(`${base}/showcase`),
      Icon: Eye,
      group: "main",
    },
    {
      href: `${base}/inbox`,
      label: "Inbox",
      match: (p) => p.startsWith(`${base}/inbox`),
      Icon: Inbox,
      group: "main",
    },
  ];
}

type VenueWorkspaceShellProps = {
  venueId: string;
  title: string;
  children: ReactNode;
  venueName?: string;
};

export function VenueWorkspaceShell({
  venueId,
  title,
  children,
  venueName,
}: VenueWorkspaceShellProps) {
  return (
    <ServiceWorkspaceShell
      service="venue"
      brandTitle="Бронь"
      brandSubtitle={venueName ?? "План зала"}
      title={title}
      nav={venueNav(venueId)}
      hubPath={`/app/settings/venue/v/${venueId}`}
      hubBackHref="/app/settings/venue"
      backHref={`/app/settings/venue/v/${venueId}`}
      maxWidthClassName="max-w-[1600px]"
    >
      {children}
    </ServiceWorkspaceShell>
  );
}
