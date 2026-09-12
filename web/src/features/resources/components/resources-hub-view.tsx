"use client";

import { BookOpen, ChevronRight, MapPin, SlidersHorizontal } from "lucide-react";
import Link from "next/link";
import { serviceTileIcon } from "@/lib/service-accent";
import { ResourcesWorkspaceShell } from "@/features/resources/components/resources-workspace-shell";

/** Хаб «Ресурсы». Гайд — один тайл → детальная страница. */
export function ResourcesHubView() {
  return (
    <ResourcesWorkspaceShell title="Ресурсы">
      <div className="space-y-6">
        <section>
          <p className="mb-2 px-1 text-[12px] font-bold uppercase tracking-wide text-muted">
            Справочники
          </p>
          <ul className="overflow-hidden rounded-[16px] border border-line bg-surface lg:grid lg:grid-cols-2 lg:gap-0">
            <li className="border-b border-line lg:border-b-0 lg:border-r">
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
            Помощь
          </p>
          <ul className="overflow-hidden rounded-[16px] border border-line bg-surface">
            <li>
              <Link
                href="/app/settings/resources/guide/overview"
                className="flex items-center gap-3 px-3.5 py-3.5 transition hover:bg-svc-resources/40"
              >
                <span className={serviceTileIcon("resources")}>
                  <BookOpen className="h-5 w-5" strokeWidth={2} />
                </span>
                <span className="min-w-0 flex-1">
                  <span className="block text-[15px] font-bold text-ink">Гайд</span>
                  <span className="block text-[12px] text-muted">
                    Что такое ресурсы — идея сервиса
                  </span>
                </span>
                <ChevronRight className="h-5 w-5 text-muted" strokeWidth={2} />
              </Link>
            </li>
          </ul>
        </section>
      </div>
    </ResourcesWorkspaceShell>
  );
}
