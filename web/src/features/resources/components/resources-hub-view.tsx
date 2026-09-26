"use client";

import { MapPin, Plus, SlidersHorizontal } from "lucide-react";
import Link from "next/link";
import { useEffect, useState } from "react";
import { AppButtonLink } from "@/components/shared/app-button";
import { ShimmerBone } from "@/components/shared/route-shimmers";
import {
  listMyLocationsAll,
  type ManagedLocation,
} from "@/features/resources/lib/locations-api";
import {
  listProfileFilterCategories,
  type ProfileFilterCategory,
} from "@/features/resources/lib/profile-filters-api";
import {
  readResourcesLocationsCache,
  readResourcesProfileFiltersCache,
  writeResourcesLocationsCache,
  writeResourcesProfileFiltersCache,
} from "@/features/resources/lib/resources-prefs";
import { ResourcesWorkspaceShell } from "@/features/resources/components/resources-workspace-shell";
import {
  ServiceEmpty,
  ServiceInformer,
  ServiceSection,
} from "@/features/shared/components/service-page";
import { getSessionUserId, runServiceSwr } from "@/lib/run-service-swr";

const LOCATIONS_HREF = "/app/settings/resources/locations";
const FILTERS_HREF = "/app/settings/resources/filters";
const PREVIEW_LIMIT = 4;

function locationTitle(loc: ManagedLocation): string {
  return loc.addressCyrillic || loc.addressPrimary || "Без адреса";
}

/** Обзор «Ресурсов»: что уже есть в справочнике, без второго меню. */
export function ResourcesHubView() {
  const [locations, setLocations] = useState<ManagedLocation[] | null>(null);
  const [filters, setFilters] = useState<ProfileFilterCategory[] | null>(null);
  const [locationsLoading, setLocationsLoading] = useState(true);
  const [filtersLoading, setFiltersLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    void runServiceSwr({
      read: readResourcesLocationsCache,
      fetch: listMyLocationsAll,
      write: writeResourcesLocationsCache,
      apply: setLocations,
      setLoading: setLocationsLoading,
      setError,
    });
    void (async () => {
      const uid = await getSessionUserId();
      if (!uid) {
        setFiltersLoading(false);
        return;
      }
      await runServiceSwr({
        read: readResourcesProfileFiltersCache,
        fetch: () => listProfileFilterCategories(uid),
        write: writeResourcesProfileFiltersCache,
        apply: setFilters,
        setLoading: setFiltersLoading,
        setError,
      });
    })();
  }, []);

  const activeCount = locations?.filter((l) => l.isActive).length ?? 0;
  const inactiveCount = (locations?.length ?? 0) - activeCount;
  const valuesCount = filters?.reduce((sum, c) => sum + c.values.length, 0) ?? 0;
  const ready = !locationsLoading && !filtersLoading;

  return (
    <ResourcesWorkspaceShell
      title="Обзор"
      lead="Ваш справочник для постов и витрины профиля: места и фильтры."
    >
      <div className="mx-auto max-w-3xl space-y-5 pb-10">
        {error ? (
          <p className="rounded-[12px] bg-destructive/10 px-3 py-2 text-center text-[12px] font-semibold text-destructive">
            {error}
          </p>
        ) : null}

        {ready ? (
          <ServiceInformer service="resources">
            Мест {locations?.length ?? 0} · активных {activeCount} · фильтров{" "}
            {filters?.length ?? 0} · значений {valuesCount}
          </ServiceInformer>
        ) : (
          <ShimmerBone className="h-10 w-full rounded-[14px]" />
        )}

        <ServiceSection
          title="Местоположения"
          action={
            locations && locations.length > 0 ? (
              <Link
                href={LOCATIONS_HREF}
                className="text-[12px] font-bold text-svc-resources-ink hover:underline"
              >
                Все местоположения
              </Link>
            ) : null
          }
        >
          <p className="mb-3 text-[12px] leading-snug text-muted">
            Адреса с точкой на карте. Активное место можно выбрать в новом посте.
          </p>
          {locationsLoading ? (
            <PreviewShimmer />
          ) : !locations || locations.length === 0 ? (
            <ServiceEmpty
              action={
                <AppButtonLink
                  href={`${LOCATIONS_HREF}/new`}
                  service="resources"
                  size="row"
                  className="gap-1.5"
                >
                  <Plus className="h-4 w-4" strokeWidth={2.5} />
                  Добавить место
                </AppButtonLink>
              }
            >
              Пока нет мест. Добавьте первое — и его можно будет отметить в посте.
            </ServiceEmpty>
          ) : (
            <div className="space-y-3">
              <ul className="space-y-1.5">
                {locations.slice(0, PREVIEW_LIMIT).map((loc) => (
                  <li key={loc.id}>
                    <Link
                      href={`${LOCATIONS_HREF}/${loc.id}`}
                      className="flex items-center gap-3 rounded-[14px] border border-line bg-surface px-3 py-2.5 transition hover:bg-svc-resources/30"
                    >
                      <span className="flex h-9 w-9 shrink-0 items-center justify-center rounded-[10px] bg-svc-resources text-svc-resources-ink">
                        <MapPin className="h-4 w-4" strokeWidth={2} />
                      </span>
                      <span className="min-w-0 flex-1 truncate text-[14px] font-semibold text-ink">
                        {locationTitle(loc)}
                      </span>
                      {!loc.isActive ? (
                        <span className="shrink-0 text-[11px] font-bold text-muted">
                          Неактивно
                        </span>
                      ) : null}
                    </Link>
                  </li>
                ))}
              </ul>
              {locations.length > PREVIEW_LIMIT ? (
                <p className="text-[12px] text-muted">
                  И ещё {locations.length - PREVIEW_LIMIT} в разделе «Местоположения».
                </p>
              ) : null}
              {inactiveCount > 0 ? (
                <ServiceInformer service="resources" tone="warning">
                  Неактивных: {inactiveCount}. Их нельзя выбрать в новом посте, старые
                  посты не меняются.
                </ServiceInformer>
              ) : null}
            </div>
          )}
        </ServiceSection>

        <ServiceSection
          title="Фильтры витрины"
          action={
            filters && filters.length > 0 ? (
              <Link
                href={FILTERS_HREF}
                className="text-[12px] font-bold text-svc-resources-ink hover:underline"
              >
                Все фильтры
              </Link>
            ) : null
          }
        >
          <p className="mb-3 text-[12px] leading-snug text-muted">
            Категории над сеткой профиля. Гости сужают по ним посты, а вы отмечаете их при
            публикации.
          </p>
          {filtersLoading ? (
            <PreviewShimmer />
          ) : !filters || filters.length === 0 ? (
            <ServiceEmpty
              action={
                <AppButtonLink
                  href={FILTERS_HREF}
                  service="resources"
                  size="row"
                  className="gap-1.5"
                >
                  <SlidersHorizontal className="h-4 w-4" strokeWidth={2} />
                  Создать фильтр
                </AppButtonLink>
              }
            >
              Пока нет фильтров. Например: «Услуга» — стрижка, окрашивание.
            </ServiceEmpty>
          ) : (
            <ul className="space-y-1.5">
              {filters.slice(0, PREVIEW_LIMIT).map((c) => (
                <li
                  key={c.id}
                  className="rounded-[14px] border border-line bg-surface px-3 py-2.5"
                >
                  <p className="text-[14px] font-semibold text-ink">{c.name}</p>
                  <p className="mt-0.5 truncate text-[12px] text-muted">
                    {c.values.length ? c.values.join(" · ") : "Нет значений"}
                  </p>
                </li>
              ))}
            </ul>
          )}
        </ServiceSection>
      </div>
    </ResourcesWorkspaceShell>
  );
}

function PreviewShimmer() {
  return (
    <div className="space-y-1.5" aria-busy="true" aria-label="Загрузка">
      {Array.from({ length: 3 }).map((_, i) => (
        <ShimmerBone key={i} className="h-12 w-full rounded-[14px]" />
      ))}
    </div>
  );
}
