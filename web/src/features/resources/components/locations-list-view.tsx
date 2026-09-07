"use client";

import { MapPin, Plus } from "lucide-react";
import Link from "next/link";
import { useCallback, useEffect, useState } from "react";
import { AppButtonLink } from "@/components/shared/app-button";
import { cityLabel, countryLabel } from "@/features/catalog/lib/locations";
import {
  listMyLocationsAll,
  type ManagedLocation,
} from "@/features/resources/lib/locations-api";
import { SettingsShell } from "@/features/settings/components/settings-shell";

export function LocationsListView() {
  const [items, setItems] = useState<ManagedLocation[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const load = useCallback(() => {
    setLoading(true);
    void listMyLocationsAll()
      .then(setItems)
      .catch((e: unknown) =>
        setError(e instanceof Error ? e.message : "Не удалось загрузить"),
      )
      .finally(() => setLoading(false));
  }, []);

  useEffect(() => {
    load();
  }, [load]);

  return (
    <SettingsShell
      title="Местоположения"
      backHref="/app/settings/resources"
      service="resources"
      trailing={
        <AppButtonLink
          href="/app/settings/resources/locations/new"
          size="icon"
          service="resources"
          aria-label="Добавить"
          title="Добавить"
        >
          <Plus strokeWidth={2.5} />
        </AppButtonLink>
      }
    >
      <div className="px-4 py-4">
        {error ? (
          <p className="mb-3 text-center text-[12px] font-semibold text-destructive">{error}</p>
        ) : null}
        {loading ? (
          <p className="py-16 text-center text-sm text-muted">Загрузка…</p>
        ) : items.length === 0 ? (
          <div className="py-16 text-center">
            <MapPin className="mx-auto h-8 w-8 text-svc-resources-ink/50" strokeWidth={1.5} />
            <p className="mt-3 text-sm font-semibold text-ink">Пока нет мест</p>
            <Link
              href="/app/settings/resources/locations/new"
              className="mt-2 inline-block text-[13px] font-bold text-svc-resources-ink"
            >
              Добавить местоположение
            </Link>
          </div>
        ) : (
          <ul className="space-y-2">
            {items.map((loc) => {
              const geo =
                loc.countryCode || loc.cityCode
                  ? [countryLabel(loc.countryCode), cityLabel(loc.countryCode, loc.cityCode)]
                      .filter(Boolean)
                      .join(" · ")
                  : null;
              return (
                <li key={loc.id}>
                  <Link
                    href={`/app/settings/resources/locations/${loc.id}`}
                    className={`flex gap-3 rounded-[16px] border px-3.5 py-3 transition hover:bg-svc-resources/30 ${
                      loc.isActive
                        ? "border-line bg-surface"
                        : "border-line/60 bg-surface-muted opacity-70"
                    }`}
                  >
                    <span className="flex h-10 w-10 shrink-0 items-center justify-center rounded-[12px] bg-svc-resources text-svc-resources-ink">
                      <MapPin className="h-5 w-5" strokeWidth={2} />
                    </span>
                    <span className="min-w-0 flex-1">
                      <span className="block truncate text-[15px] font-bold text-ink">
                        {loc.addressCyrillic || loc.addressPrimary || "Без адреса"}
                      </span>
                      {loc.addressCyrillic &&
                      loc.addressPrimary &&
                      loc.addressPrimary !== loc.addressCyrillic ? (
                        <span className="mt-0.5 block truncate text-[12px] text-muted">
                          {loc.addressPrimary}
                        </span>
                      ) : null}
                      {geo ? (
                        <span className="mt-0.5 block truncate text-[12px] text-muted">{geo}</span>
                      ) : null}
                      {!loc.isActive ? (
                        <span className="mt-1 inline-block text-[11px] font-bold text-muted">
                          Неактивно
                        </span>
                      ) : null}
                    </span>
                  </Link>
                </li>
              );
            })}
          </ul>
        )}
      </div>
    </SettingsShell>
  );
}
