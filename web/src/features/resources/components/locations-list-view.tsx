"use client";

import { MapPin, Plus } from "lucide-react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { useCallback, useEffect, useState } from "react";
import { AppButtonLink } from "@/components/shared/app-button";
import { cityLabel, countryLabel } from "@/features/catalog/lib/locations";
import {
  listMyLocationsAll,
  type ManagedLocation,
} from "@/features/resources/lib/locations-api";
import {
  readResourcesLocationsCache,
  writeResourcesLocationsCache,
} from "@/features/resources/lib/resources-prefs";
import { ResourcesWorkspaceShell } from "@/features/resources/components/resources-workspace-shell";
import {
  ServiceEmpty,
  ServiceInformer,
  ServiceListShimmer,
} from "@/features/shared/components/service-page";
import { MapboxPinMap } from "@/features/maps/mapbox-pin-map";
import { runServiceSwr } from "@/lib/run-service-swr";

export function LocationsListView() {
  const router = useRouter();
  const [items, setItems] = useState<ManagedLocation[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [selectedId, setSelectedId] = useState<string | null>(null);

  const applyList = useCallback((list: ManagedLocation[]) => {
    setItems(list);
    setSelectedId((prev) => {
      if (prev && list.some((l) => l.id === prev)) return prev;
      return list[0]?.id ?? null;
    });
  }, []);

  useEffect(() => {
    void runServiceSwr({
      read: readResourcesLocationsCache,
      fetch: listMyLocationsAll,
      write: writeResourcesLocationsCache,
      apply: applyList,
      setLoading,
      setError,
    });
  }, [applyList]);

  const selected = items.find((l) => l.id === selectedId) ?? null;
  const selectedPin =
    selected?.latitude != null && selected.longitude != null
      ? { lat: selected.latitude, lon: selected.longitude }
      : null;
  const activeCount = items.filter((l) => l.isActive).length;

  return (
    <ResourcesWorkspaceShell
      title="Местоположения"
      lead="Адреса с точкой на карте, которые вы отмечаете в постах."
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
      <div className="space-y-4">
        {error ? (
          <p className="rounded-[12px] bg-destructive/10 px-3 py-2 text-center text-[12px] font-semibold text-destructive">
            {error}
          </p>
        ) : null}
        {loading ? (
          <ServiceListShimmer rows={4} />
        ) : items.length === 0 ? (
          <ServiceEmpty
            action={
              <AppButtonLink
                href="/app/settings/resources/locations/new"
                service="resources"
                size="row"
                className="gap-1.5"
              >
                <Plus className="h-4 w-4" strokeWidth={2.5} />
                Добавить место
              </AppButtonLink>
            }
          >
            Пока нет мест. Поставьте пин на карте и укажите адрес.
          </ServiceEmpty>
        ) : (
          <>
            <ServiceInformer service="resources">
              Всего {items.length} · активных {activeCount}. Неактивное место остаётся в
              списке, но его нельзя выбрать в новом посте.
            </ServiceInformer>
            <div className="grid gap-4 lg:grid-cols-[minmax(0,1fr)_minmax(300px,420px)] lg:items-start">
              <ul className="space-y-2">
                {items.map((loc) => {
                  const geo =
                    loc.countryCode || loc.cityCode
                      ? [countryLabel(loc.countryCode), cityLabel(loc.countryCode, loc.cityCode)]
                          .filter(Boolean)
                          .join(" · ")
                      : null;
                  const active = selectedId === loc.id;
                  return (
                    <li key={loc.id}>
                      <button
                        type="button"
                        onClick={() => {
                          if (
                            typeof window !== "undefined" &&
                            window.matchMedia("(min-width: 1024px)").matches
                          ) {
                            setSelectedId(loc.id);
                            return;
                          }
                          router.push(`/app/settings/resources/locations/${loc.id}`);
                        }}
                        className={`flex w-full gap-3 rounded-[16px] border px-3.5 py-3 text-left transition hover:bg-svc-resources/30 ${
                          active
                            ? "border-svc-resources-ink/40 bg-svc-resources ring-1 ring-svc-resources-ink/25"
                            : loc.isActive
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
                      </button>
                    </li>
                  );
                })}
              </ul>

              <aside className="hidden lg:block">
                <div className="sticky top-4 space-y-3 rounded-[16px] border border-line bg-surface p-4">
                  {selected ? (
                    <>
                      <p className="text-[11px] font-bold uppercase tracking-wide text-muted">
                        На карте
                      </p>
                      <p className="text-[16px] font-bold text-ink">
                        {selected.addressCyrillic || selected.addressPrimary || "Без адреса"}
                      </p>
                      {selectedPin ? (
                        <MapboxPinMap
                          hostId="resources-location-preview"
                          className="h-56 w-full overflow-hidden rounded-[12px] border border-line bg-mint"
                          initialCenter={selectedPin}
                          pin={selectedPin}
                          zoom={15}
                        />
                      ) : (
                        <p className="py-8 text-center text-[13px] text-muted">
                          Нет координат для карты
                        </p>
                      )}
                      <dl className="space-y-1.5 text-[13px]">
                        <div className="flex justify-between gap-2">
                          <dt className="text-muted">Координаты</dt>
                          <dd className="font-semibold text-ink">
                            {selected.latitude != null && selected.longitude != null
                              ? `${selected.latitude.toFixed(5)}, ${selected.longitude.toFixed(5)}`
                              : "—"}
                          </dd>
                        </div>
                        <div className="flex justify-between gap-2">
                          <dt className="text-muted">Статус</dt>
                          <dd className="font-semibold text-ink">
                            {selected.isActive ? "Активно" : "Неактивно"}
                          </dd>
                        </div>
                      </dl>
                      <Link
                        href={`/app/settings/resources/locations/${selected.id}`}
                        className="inline-block text-[13px] font-bold text-svc-resources-ink hover:underline"
                      >
                        Редактировать
                      </Link>
                    </>
                  ) : (
                    <ServiceEmpty>Выберите место слева, чтобы увидеть его на карте.</ServiceEmpty>
                  )}
                </div>
              </aside>
            </div>
          </>
        )}
      </div>
    </ResourcesWorkspaceShell>
  );
}
