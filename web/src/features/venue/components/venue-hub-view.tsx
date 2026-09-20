"use client";

import {
  CalendarClock,
  ChevronRight,
  Eye,
  Inbox,
  Layers,
  Ticket,
} from "lucide-react";
import Link from "next/link";
import { serviceTileIcon } from "@/lib/service-accent";
import { VenueWorkspaceShell } from "@/features/venue/components/venue-workspace-shell";
import { ladderLabel } from "@/features/venue/lib/venue-booking-mock";

const NAMES: Record<string, string> = {
  cafe: "Кафе Clover",
  cinema: "Кино Star",
  poetry: "Вечер поэзии",
};

const LINKS = [
  {
    href: "bookables",
    title: "Объекты брони",
    subtitle: "Bookable · билет / стол / зона",
    Icon: Ticket,
  },
  {
    href: "sessions",
    title: "Сеансы и слоты",
    subtitle: "Occasion · когда считают занятость",
    Icon: CalendarClock,
  },
  {
    href: "plan",
    title: "План",
    subtitle: "Фигуры · этажи · привязка к bookable",
    Icon: Layers,
  },
  {
    href: "showcase",
    title: "Витрина",
    subtitle: "Гость: occasion → свободные bookable",
    Icon: Eye,
  },
  {
    href: "inbox",
    title: "Inbox",
    subtitle: "Запросы (reservation) · подтвердить / отклонить",
    Icon: Inbox,
  },
] as const;

export function VenueHubView({ venueId }: { venueId: string }) {
  const name = NAMES[venueId] ?? "Заведение";
  const base = `/app/settings/venue/v/${venueId}`;

  return (
    <VenueWorkspaceShell venueId={venueId} title={name} venueName={name}>
      <div className="mx-auto max-w-2xl space-y-5">
        <div className="rounded-[20px] border border-line bg-surface px-4 py-3.5">
          <p className="text-[15px] font-bold text-ink">Логика брони</p>
          <p className="mt-1 text-[13px] leading-relaxed text-muted">
            <span className="font-semibold text-ink">reservation</span> ={" "}
            <span className="font-semibold text-ink">bookable</span> +{" "}
            <span className="font-semibold text-ink">occasion</span>; занятость —{" "}
            <span className="font-semibold text-ink">inventory</span> на эту пару.{" "}
            {ladderLabel(venueId)}. Мок без бэка.
          </p>
        </div>

        <ul className="overflow-hidden rounded-[20px] border border-line bg-surface">
          {LINKS.map(({ href, title, subtitle, Icon }, i) => (
            <Link
              key={href}
              href={`${base}/${href}`}
              className={`flex items-center gap-3 px-4 py-3.5 transition hover:bg-svc-venue/40 ${
                i > 0 ? "border-t border-line" : ""
              }`}
            >
              <span className={serviceTileIcon("venue")}>
                <Icon className="h-5 w-5" strokeWidth={2} />
              </span>
              <span className="min-w-0 flex-1">
                <span className="block text-[15px] font-bold text-ink">{title}</span>
                <span className="block text-[12px] text-muted">{subtitle}</span>
              </span>
              <ChevronRight className="h-4 w-4 text-icon-muted" />
            </Link>
          ))}
        </ul>
      </div>
    </VenueWorkspaceShell>
  );
}
