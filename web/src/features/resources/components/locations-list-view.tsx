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
import { getSessionUserId } from "@/lib/run-service-swr";

function osmEmbed(lat: number, lon: number): string {
  const d = 0.012;
  const bbox = `${lon - d}%2C${lat - d}%2C${lon + d}%2C${lat + d}`;
  return `https://www.openstreetmap.org/export/embed.html?bbox=${bbox}&layer=mapnik&marker=${lat}%2C${lon}`;
}

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

  const load = useCallback(async (opts?: { soft?: boolean }) => {
    if (!opts?.soft) setLoading(true);
    setError(null);
    try {
      const uid = await getSessionUserId();
      const list = await listMyLocationsAll();
      applyList(list);
      writeResourcesLocationsCache(uid, list);
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : "Не удалось загрузить");
    } finally {
      setLoading(false);
    }
  }, [applyList]);

  useEffect(() => {
    void (async () => {
      const uid = await getSessionUserId();
      const cached = readResourcesLocationsCache(uid);
      if (cached) {
        applyList(cached);
        setLoading(false);
        await load({ soft: true });
      } else {
        await load();
      }
    })();
  }, [applyList, load]);

  const selected = items.find((l) => l.id === selectedId) ?? null;

  return (
    <ResourcesWorkspaceShell
      title="Местоположения"
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
      <div>
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
                      Превью
                    </p>
                    <p className="text-[16px] font-bold text-ink">
                      {selected.addressCyrillic || selected.addressPrimary || "Без адреса"}
                    </p>
                    {selected.latitude != null && selected.longitude != null ? (
                      <div className="overflow-hidden rounded-[12px] border border-line">
                        <iframe
                          title="Карта"
                          className="h-56 w-full border-0"
                          loading="lazy"
                          referrerPolicy="no-referrer-when-downgrade"
                          src={osmEmbed(selected.latitude, selected.longitude)}
                        />
                      </div>
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
                  <p className="py-12 text-center text-[13px] text-muted">
                    Выберите локацию слева
                  </p>
                )}
              </div>
            </aside>
          </div>
        )}
      </div>
    </ResourcesWorkspaceShell>
  );
}
