"use client";

import { useRouter } from "next/navigation";
import { useId, useState, useTransition } from "react";
import { AppButton } from "@/components/shared/app-button";
import {
  citiesForCountry,
  COUNTRY_OPTIONS,
} from "@/features/catalog/lib/locations";
import { MapboxPinMap } from "@/features/maps/mapbox-pin-map";
import { createManagedLocation } from "@/features/resources/lib/locations-api";
import { ResourcesWorkspaceShell } from "@/features/resources/components/resources-workspace-shell";

const ALMATY = { lat: 43.238949, lon: 76.889709 };

export function LocationCreateView() {
  const router = useRouter();
  const hostId = useId().replace(/:/g, "");
  const [pin, setPin] = useState(ALMATY);
  const [addressCyrillic, setAddressCyrillic] = useState("");
  const [addressLatin, setAddressLatin] = useState("");
  const [countryCode, setCountryCode] = useState("kz");
  const [cityCode, setCityCode] = useState("almaty");
  const [error, setError] = useState<string | null>(null);
  const [mapError, setMapError] = useState<string | null>(null);
  const [, startTransition] = useTransition();
  const [saving, setSaving] = useState(false);

  const cities = citiesForCountry(countryCode);

  const submit = () => {
    setSaving(true);
    setError(null);
    startTransition(async () => {
      try {
        await createManagedLocation({
          addressCyrillic,
          addressLatin,
          latitude: pin.lat,
          longitude: pin.lon,
          countryCode,
          cityCode,
        });
        router.push("/app/settings/resources/locations");
        router.refresh();
      } catch (e: unknown) {
        setError(e instanceof Error ? e.message : "Не удалось сохранить");
        setSaving(false);
      }
    });
  };

  return (
    <ResourcesWorkspaceShell
      title="Новое место"
      backHref="/app/settings/resources/locations"
    >
      <div className="grid gap-6 lg:grid-cols-2 lg:items-start">
        <div>
          <p className="mb-2 text-[13px] font-semibold text-ink">Точка на карте</p>
          <p className="mb-2 text-[12px] text-muted">Тапните карту, чтобы поставить пин</p>
          {mapError ? (
            <p className="rounded-[12px] border border-line bg-surface-muted px-3 py-8 text-center text-[13px] text-muted">
              {mapError}
            </p>
          ) : (
            <MapboxPinMap
              hostId={hostId}
              className="h-[240px] w-full overflow-hidden rounded-[16px] border border-line bg-mint lg:h-[360px]"
              initialCenter={ALMATY}
              pin={pin}
              onPinChange={setPin}
              onReadyError={setMapError}
            />
          )}
          <p className="mt-1.5 text-[11px] text-muted">
            {pin.lat.toFixed(5)}, {pin.lon.toFixed(5)}
          </p>
        </div>

        <div className="flex flex-col gap-4">
          {error ? (
            <p className="rounded-[12px] bg-destructive/10 px-3 py-2 text-center text-[12px] font-semibold text-destructive">
              {error}
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
                  const first = citiesForCountry(cc)[0];
                  setCityCode(first?.code ?? "");
                }}
                className="h-12 w-full rounded-[14px] border border-line bg-surface px-3 text-[15px] text-ink outline-none focus:border-svc-resources-ink"
              >
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
                className="h-12 w-full rounded-[14px] border border-line bg-surface px-3 text-[15px] text-ink outline-none focus:border-svc-resources-ink"
              >
                {cities.map((c) => (
                  <option key={c.code} value={c.code}>
                    {c.label}
                  </option>
                ))}
              </select>
            </label>
          </div>

          <AppButton
            type="button"
            service="resources"
            loading={saving}
            disabled={!addressCyrillic.trim() || saving}
            onClick={submit}
          >
            Сохранить
          </AppButton>
        </div>
      </div>
    </ResourcesWorkspaceShell>
  );
}
