"use client";

import { ChevronRight, Layers, MapPin, SlidersHorizontal } from "lucide-react";
import Link from "next/link";
import { serviceTileIcon } from "@/lib/service-accent";
import { SettingsShell } from "@/features/settings/components/settings-shell";
import { RESOURCES_GUIDE } from "@/features/resources/lib/resources-guide";

const GUIDE_ICONS = {
  overview: Layers,
  locations: MapPin,
  filters: SlidersHorizontal,
} as const;

/** Хаб «Ресурсы». Ярлык на профиле — по тегу `resources`, не prefs. */
export function ResourcesHubView() {
  return (
    <SettingsShell title="Ресурсы" service="resources">
      <div className="space-y-6 px-4 py-5">
        <section>
          <p className="mb-2 px-1 text-[12px] font-bold uppercase tracking-wide text-muted">
            Справочники
          </p>
          <ul className="overflow-hidden rounded-[16px] border border-line bg-surface">
            <li className="border-b border-line">
              <Link
                href="/app/settings/resources/locations"
                className="flex items-center gap-3 px-3.5 py-3.5 transition hover:bg-svc-resources/40"
              >
                <span className={serviceTileIcon("resources")}>
                  <MapPin className="h-5 w-5" strokeWidth={2} />
                </span>
                <span className="min-w-0 flex-1">
                  <span className="block text-[15px] font-bold text-ink">Местоположения</span>
                  <span className="block text-[12px] text-muted">
                    Адреса и точки на карте для постов
                  </span>
                </span>
                <ChevronRight className="h-5 w-5 text-muted" strokeWidth={2} />
              </Link>
            </li>
            <li>
              <Link
                href="/app/settings/resources/filters"
                className="flex items-center gap-3 px-3.5 py-3.5 transition hover:bg-svc-resources/40"
              >
                <span className={serviceTileIcon("resources")}>
                  <SlidersHorizontal className="h-5 w-5" strokeWidth={2} />
                </span>
                <span className="min-w-0 flex-1">
                  <span className="block text-[15px] font-bold text-ink">Фильтры</span>
                  <span className="block text-[12px] text-muted">
                    Категории витрины профиля
                  </span>
                </span>
                <ChevronRight className="h-5 w-5 text-muted" strokeWidth={2} />
              </Link>
            </li>
          </ul>
        </section>

        <section>
          <p className="mb-2 px-1 text-[12px] font-bold uppercase tracking-wide text-muted">
            Гайд
          </p>
          <div className="grid gap-2.5 sm:grid-cols-3">
            {RESOURCES_GUIDE.map((item) => {
              const Icon = GUIDE_ICONS[item.topic];
              return (
                <Link
                  key={item.topic}
                  href={`/app/settings/resources/guide/${item.topic}`}
                  className="rounded-[16px] border border-line bg-surface p-3.5 transition hover:bg-svc-resources/40"
                >
                  <span className={serviceTileIcon("resources")}>
                    <Icon className="h-5 w-5" strokeWidth={2} />
                  </span>
                  <span className="mt-3 block text-[15px] font-bold text-ink">{item.cardTitle}</span>
                  <span className="mt-1 block text-[12px] leading-snug text-muted">
                    {item.cardSubtitle}
                  </span>
                </Link>
              );
            })}
          </div>
        </section>
      </div>
    </SettingsShell>
  );
}
