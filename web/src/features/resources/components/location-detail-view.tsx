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
import { SettingsShell } from "@/features/settings/components/settings-shell";

type LocationDetailViewProps = { locationId: string };

export function LocationDetailView({ locationId }: LocationDetailViewProps) {
  const router = useRouter();
  const [loc, setLoc] = useState<ManagedLocation | null>(null);
  const [addressPrimary, setAddressPrimary] = useState("");
  const [addressCyrillic, setAddressCyrillic] = useState("");
  const [countryCode, setCountryCode] = useState("");
  const [cityCode, setCityCode] = useState("");
  const [isActive, setIsActive] = useState(true);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [saving, setSaving] = useState(false);
  const [, startTransition] = useTransition();

  useEffect(() => {
    void getMyLocation(locationId)
      .then((row) => {
        if (!row) {
          setError("Место не найдено");
          return;
        }
        setLoc(row);
        setAddressPrimary(row.addressPrimary);
        setAddressCyrillic(row.addressCyrillic ?? "");
        setCountryCode(row.countryCode ?? "");
        setCityCode(row.cityCode ?? "");
        setIsActive(row.isActive);
      })
      .catch((e: unknown) =>
        setError(e instanceof Error ? e.message : "Ошибка загрузки"),
      )
      .finally(() => setLoading(false));
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
          addressPrimary,
          addressCyrillic,
          clearAddressCyrillic: !addressCyrillic.trim(),
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
    <SettingsShell
      title="Местоположение"
      backHref="/app/settings/resources/locations"
      service="resources"
    >
      <div className="flex flex-col gap-4 px-4 py-4 pb-10">
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
              <span className="mb-1.5 block text-sm font-semibold text-ink">Адрес</span>
              <input
                value={addressPrimary}
                onChange={(e) => setAddressPrimary(e.target.value)}
                className="h-12 w-full rounded-[14px] border border-line bg-surface px-4 text-[15px] text-ink outline-none focus:border-svc-resources-ink"
              />
            </label>
            <label className="block">
              <span className="mb-1.5 block text-sm font-semibold text-ink">Дополнительно</span>
              <input
                value={addressCyrillic}
                onChange={(e) => setAddressCyrillic(e.target.value)}
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
              service="resources"
              loading={saving}
              disabled={!addressPrimary.trim() || saving}
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
    </SettingsShell>
  );
}
