"use client";

import { BookOpen, MapPin, SlidersHorizontal } from "lucide-react";
import Link from "next/link";
import { ResourcesWorkspaceShell } from "@/features/resources/components/resources-workspace-shell";

const TILES = [
  {
    href: "/app/settings/resources/locations",
    label: "Местоположения",
    subtitle: "Адреса и точки на карте",
    Icon: MapPin,
  },
  {
    href: "/app/settings/resources/filters",
    label: "Фильтры",
    subtitle: "Категории витрины профиля",
    Icon: SlidersHorizontal,
  },
  {
    href: "/app/settings/resources/guide/overview",
    label: "Гайд",
    subtitle: "Что такое ресурсы",
    Icon: BookOpen,
  },
] as const;

/** Хаб «Ресурсы»: грид → местоположения / фильтры / гайд. */
export function ResourcesHubView() {
  return (
    <ResourcesWorkspaceShell title="Ресурсы">
      <div className="grid gap-3 sm:grid-cols-2">
        {TILES.map((item) => {
          const Icon = item.Icon;
          return (
            <Link
              key={item.href}
              href={item.href}
              className="flex flex-col items-start gap-3 rounded-[18px] border border-line bg-surface p-3.5 transition hover:border-svc-resources-ink/30 hover:bg-svc-resources/35"
            >
              <span className="flex h-11 w-11 items-center justify-center rounded-[14px] bg-svc-resources text-svc-resources-ink">
                <Icon className="h-5 w-5" strokeWidth={2} />
              </span>
              <span className="min-w-0">
                <span className="block text-[16px] font-bold text-ink">{item.label}</span>
                <span className="mt-1 block text-[13px] text-muted">{item.subtitle}</span>
              </span>
            </Link>
          );
        })}
      </div>
    </ResourcesWorkspaceShell>
  );
}
