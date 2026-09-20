"use client";

import { ChevronRight, Ticket } from "lucide-react";
import Link from "next/link";
import { serviceTileIcon } from "@/lib/service-accent";
import { SettingsShell } from "@/features/settings/components/settings-shell";

const VENUES = [
  {
    id: "cafe",
    name: "Кафе Clover",
    subtitle: "План зала и места",
  },
  {
    id: "cinema",
    name: "Кино Star",
    subtitle: "Кресла и сеансы",
  },
  {
    id: "poetry",
    name: "Вечер поэзии",
    subtitle: "Билеты без схемы",
  },
] as const;

export function VenueHubListView() {
  return (
    <SettingsShell title="Бронь" service="venue">
      <div className="mx-auto max-w-2xl space-y-6 px-4 py-5">
        <div>
          <p className="mb-2 text-[12px] font-bold uppercase tracking-wide text-muted">
            Заведения
          </p>
          <ul className="overflow-hidden rounded-[20px] border border-line bg-surface">
            {VENUES.map((venue, i) => (
              <li key={venue.id}>
                <Link
                  href={`/app/settings/venue/v/${venue.id}`}
                  className={`flex items-center gap-3 px-4 py-3.5 transition hover:bg-svc-venue/40 ${
                    i > 0 ? "border-t border-line" : ""
                  }`}
                >
                  <span className={serviceTileIcon("venue")}>
                    <Ticket className="h-5 w-5" strokeWidth={2} />
                  </span>
                  <span className="min-w-0 flex-1">
                    <span className="block text-[15px] font-bold text-ink">{venue.name}</span>
                    <span className="block text-[12px] text-muted">{venue.subtitle}</span>
                  </span>
                  <ChevronRight className="h-4 w-4 text-icon-muted" />
                </Link>
              </li>
            ))}
          </ul>
        </div>
      </div>
    </SettingsShell>
  );
}
