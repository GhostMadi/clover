"use client";

import { Building2, CalendarDays, ChevronRight, Layers } from "lucide-react";
import Link from "next/link";
import { serviceTileIcon } from "@/lib/service-accent";
import { SettingsShell } from "@/features/settings/components/settings-shell";
import { SERVICES_GUIDE } from "@/features/settings/lib/services-guide";

const ICONS = {
  booking: CalendarDays,
  attendance: Building2,
  resources: Layers,
} as const;

/** Хаб гайда всех сервисов. */
export function ServicesGuideHubView() {
  return (
    <SettingsShell title="Гайд" backHref="/app/settings">
      <p className="mb-4 text-[14px] leading-snug text-muted">
        Как пользоваться сервисами Clover: запись, посещаемость и ресурсы.
      </p>
      <p className="mb-2 text-[12px] font-bold uppercase tracking-wide text-muted">Сервисы</p>
      <ul className="overflow-hidden rounded-[16px] border border-line bg-surface">
        {SERVICES_GUIDE.map((item, index) => {
          const Icon = ICONS[item.service];
          return (
            <li key={item.topic}>
              {index > 0 ? <div className="h-px bg-line" /> : null}
              <Link
                href={`/app/settings/guide/${item.topic}`}
                className="flex items-center gap-3 px-4 py-3.5 transition hover:bg-bg"
              >
                <span className={serviceTileIcon(item.service)}>
                  <Icon className="h-5 w-5" strokeWidth={2} />
                </span>
                <span className="min-w-0 flex-1">
                  <span className="block text-[15px] font-semibold text-ink">{item.cardTitle}</span>
                  <span className="block text-[13px] text-muted">{item.cardSubtitle}</span>
                </span>
                <ChevronRight className="h-5 w-5 shrink-0 text-icon-muted" strokeWidth={2} />
              </Link>
            </li>
          );
        })}
      </ul>
    </SettingsShell>
  );
}
