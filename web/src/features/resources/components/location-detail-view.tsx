"use client";

import { useRouter } from "next/navigation";
import { useEffect, useState, useTransition } from "react";
import { AppButton } from "@/components/shared/app-button";
import { AppCheckboxRow } from "@/components/shared/app-checkbox";
import {
  citiesForCountry,
  COUNTRY_OPTIONS,
} from "@/features/catalog/lib/locations";
import {
  deleteManagedLocation,
  getMyLocation,
  updateManagedLocation,
  type ManagedLocation,
} from "@/features/resources/lib/locations-api";
import {
  readResourcesLocationCache,
  writeResourcesLocationCache,
  writeResourcesLocationsCache,
  readResourcesLocationsCache,
} from "@/features/resources/lib/resources-prefs";
import { ResourcesWorkspaceShell } from "@/features/resources/components/resources-workspace-shell";
import { getSessionUserId } from "@/lib/run-service-swr";

type LocationDetailViewProps = { locationId: string };

export function LocationDetailView({ locationId }: LocationDetailViewProps) {
  const router = useRouter();
  const [loc, setLoc] = useState<ManagedLocation | null>(null);
  const [addressCyrillic, setAddressCyrillic] = useState("");
  const [addressLatin, setAddressLatin] = useState("");
  const [countryCode, setCountryCode] = useState("");
  const [cityCode, setCityCode] = useState("");
  const [isActive, setIsActive] = useState(true);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [saving, setSaving] = useState(false);
  const [, startTransition] = useTransition();

  const applyLoc = (row: ManagedLocation) => {
    setLoc(row);
    const cyr = row.addressCyrillic?.trim() || "";
    const primary = row.addressPrimary.trim();
    setAddressCyrillic(cyr || primary);
    setAddressLatin(cyr && primary !== cyr ? primary : "");
    setCountryCode(row.countryCode ?? "");
    setCityCode(row.cityCode ?? "");
    setIsActive(row.isActive);
  };

  useEffect(() => {
    let cancelled = false;
    void (async () => {
      const uid = await getSessionUserId();
      if (cancelled) return;
      const cached = readResourcesLocationCache(uid, locationId);
      if (cached) {
        applyLoc(cached);
        setLoading(false);
      }
      try {
        const row = await getMyLocation(locationId);
        if (cancelled) return;
        if (!row) {
          if (!cached) setError("Место не найдено");
          setLoading(false);
          return;
        }
        applyLoc(row);
        writeResourcesLocationCache(uid, row);
        const list = readResourcesLocationsCache(uid);
        if (list) {
          writeResourcesLocationsCache(
            uid,
            list.map((l) => (l.id === row.id ? row : l)),
          );
        }
        setLoading(false);
      } catch (e: unknown) {
        if (cancelled) return;
        if (!cached) {
          setError(e instanceof Error ? e.message : "Ошибка загрузки");
        }
        setLoading(false);
      }
    })();
    return () => {
      cancelled = true;
    };
  }, [locationId]);

  const cities = countryCode ? citiesForCountry(countryCode) : [];

  const save = () => {
    setSaving(true);
    setError(null);
    startTransition(async () => {
      try {
        const clearGeo = !countryCode || !cityCode;
        await updateManagedLocation({
          id: locationId,
          addressCyrillic,
          addressLatin,
          clearAddressLatin: !addressLatin.trim(),
          clearGeoBinding: clearGeo,
          countryCode: clearGeo ? null : countryCode,
          cityCode: clearGeo ? null : cityCode,
          isActive,
        });
        router.push("/app/settings/resources/locations");
        router.refresh();
      } catch (e: unknown) {
        setError(e instanceof Error ? e.message : "Не удалось сохранить");
        setSaving(false);
      }
    });
  };

  const remove = () => {
    if (!confirm("Удалить это местоположение?")) return;
    setSaving(true);
    startTransition(async () => {
      try {
        await deleteManagedLocation(locationId);
        router.push("/app/settings/resources/locations");
        router.refresh();
      } catch (e: unknown) {
        setError(e instanceof Error ? e.message : "Не удалось удалить");
        setSaving(false);
      }
    });
  };

  return (
    <ResourcesWorkspaceShell
      title="Местоположение"
      backHref="/app/settings/resources/locations"
    >
      <div className="mx-auto flex max-w-3xl flex-col gap-4 lg:grid lg:max-w-5xl lg:grid-cols-2 lg:gap-6">
        {loading ? (
          <p className="py-16 text-center text-sm text-muted">Загрузка…</p>
        ) : null}
        {error ? (
          <p className="rounded-[12px] bg-destructive/10 px-3 py-2 text-center text-[12px] font-semibold text-destructive">
            {error}
          </p>
        ) : null}
        {loc ? (
          <>
            {loc.latitude != null && loc.longitude != null ? (
              <p className="text-[12px] text-muted">
                Координаты: {loc.latitude.toFixed(5)}, {loc.longitude.toFixed(5)} (без
                перепина)
              </p>
            ) : null}
            <label className="block">
              <span className="mb-1.5 block text-sm font-semibold text-ink">
                Адрес (кириллица)
              </span>
              <input
                value={addressCyrillic}
                onChange={(e) => setAddressCyrillic(e.target.value)}
                placeholder="ул. Абая, 150, Алматы"
                className="h-12 w-full rounded-[14px] border border-line bg-surface px-4 text-[15px] text-ink outline-none focus:border-svc-resources-ink"
              />
            </label>
            <label className="block">
              <span className="mb-1.5 block text-sm font-semibold text-ink">
                Адрес (латиница)
              </span>
              <input
                value={addressLatin}
                onChange={(e) => setAddressLatin(e.target.value)}
                placeholder="Abay ave, 150, Almaty — по желанию"
                className="h-12 w-full rounded-[14px] border border-line bg-surface px-4 text-[15px] text-ink outline-none focus:border-svc-resources-ink"
              />
            </label>
            <div className="grid grid-cols-2 gap-3">
              <label className="block">
                <span className="mb-1.5 block text-sm font-semibold text-ink">Страна</span>
                <select
                  value={countryCode}
                  onChange={(e) => {
                    const cc = e.target.value;
                    setCountryCode(cc);
                    setCityCode(citiesForCountry(cc)[0]?.code ?? "");
                  }}
                  className="h-12 w-full rounded-[14px] border border-line bg-surface px-3 text-[15px] text-ink outline-none focus:border-svc-resources-ink"
                >
                  <option value="">—</option>
                  {COUNTRY_OPTIONS.map((c) => (
                    <option key={c.code} value={c.code}>
                      {c.label}
                    </option>
                  ))}
                </select>
              </label>
              <label className="block">
                <span className="mb-1.5 block text-sm font-semibold text-ink">Город</span>
                <select
                  value={cityCode}
                  onChange={(e) => setCityCode(e.target.value)}
                  disabled={!countryCode}
                  className="h-12 w-full rounded-[14px] border border-line bg-surface px-3 text-[15px] text-ink outline-none focus:border-svc-resources-ink disabled:opacity-40"
                >
                  <option value="">—</option>
                  {cities.map((c) => (
                    <option key={c.code} value={c.code}>
                      {c.label}
                    </option>
                  ))}
                </select>
              </label>
            </div>
            <AppCheckboxRow
              title="Активно"
              subtitle="Неактивные нельзя выбрать в новом посте"
              checked={isActive}
              onChange={setIsActive}
            />
            <AppButton
              type="button"
             
              loading={saving}
              disabled={!addressCyrillic.trim() || saving}
              onClick={save}
            >
              Сохранить
            </AppButton>
            <AppButton
              type="button"
              variant="outline"
              disabled={saving}
              className="!border-destructive/40 !text-destructive"
              onClick={remove}
            >
              Удалить
            </AppButton>
          </>
        ) : null}
      </div>
    </ResourcesWorkspaceShell>
  );
}
