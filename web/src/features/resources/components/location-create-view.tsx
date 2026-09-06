"use client";

import { useRouter } from "next/navigation";
import { useEffect, useId, useRef, useState, useTransition } from "react";
import { AppButton } from "@/components/shared/app-button";
import {
  citiesForCountry,
  COUNTRY_OPTIONS,
} from "@/features/catalog/lib/locations";
import { createManagedLocation } from "@/features/resources/lib/locations-api";
import { SettingsShell } from "@/features/settings/components/settings-shell";

const ALMATY = { lat: 43.238949, lon: 76.889709 };

type MapHandle = {
  destroy: () => void;
  events: { add: (name: string, cb: (e: { get: (k: string) => number[] }) => void) => void };
  geoObjects: { removeAll: () => void; add: (obj: unknown) => void };
};

type YmapsNs = {
  ready: (cb: () => void) => void;
  Map: new (el: HTMLElement, opts: object) => MapHandle;
  Placemark: new (coords: number[], props?: object, opts?: object) => unknown;
};

function getYmaps(): YmapsNs | undefined {
  return (window as unknown as { ymaps?: YmapsNs }).ymaps;
}

function loadYmaps(apiKey: string): Promise<YmapsNs> {
  const existing = getYmaps();
  if (existing) {
    return new Promise((resolve) => existing.ready(() => resolve(existing)));
  }
  const scriptExisting = document.querySelector<HTMLScriptElement>("script[data-yandex-maps]");
  if (scriptExisting) {
    return new Promise((resolve, reject) => {
      scriptExisting.addEventListener("load", () => {
        const y = getYmaps();
        if (!y) reject(new Error("Карта не загрузилась"));
        else y.ready(() => resolve(y));
      });
      scriptExisting.addEventListener("error", () => reject(new Error("Карта не загрузилась")));
    });
  }
  return new Promise((resolve, reject) => {
    const script = document.createElement("script");
    script.dataset.yandexMaps = "1";
    script.src = `https://api-maps.yandex.ru/2.1/?apikey=${encodeURIComponent(apiKey)}&lang=ru_RU`;
    script.async = true;
    script.onload = () => {
      const y = getYmaps();
      if (!y) reject(new Error("Карта не загрузилась"));
      else y.ready(() => resolve(y));
    };
    script.onerror = () => reject(new Error("Карта не загрузилась"));
    document.head.appendChild(script);
  });
}

export function LocationCreateView() {
  const router = useRouter();
  const hostId = useId().replace(/:/g, "");
  const mapRef = useRef<MapHandle | null>(null);
  const [pin, setPin] = useState(ALMATY);
  const [addressPrimary, setAddressPrimary] = useState("");
  const [addressCyrillic, setAddressCyrillic] = useState("");
  const [countryCode, setCountryCode] = useState("kz");
  const [cityCode, setCityCode] = useState("almaty");
  const [error, setError] = useState<string | null>(null);
  const [mapError, setMapError] = useState<string | null>(null);
  const [, startTransition] = useTransition();
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    const key = process.env.NEXT_PUBLIC_YANDEX_MAPS_API_KEY?.trim();
    if (!key) {
      setMapError("Нет ключа карты");
      return;
    }
    let cancelled = false;
    void loadYmaps(key)
      .then((ymaps) => {
        if (cancelled) return;
        const el = document.getElementById(`loc-pick-${hostId}`);
        if (!el) return;
        const map = new ymaps.Map(el, {
          center: [ALMATY.lat, ALMATY.lon],
          zoom: 12,
          controls: ["zoomControl"],
        });
        mapRef.current = map;
        const place = (lat: number, lon: number) => {
          map.geoObjects.removeAll();
          map.geoObjects.add(
            new ymaps.Placemark([lat, lon], {}, { preset: "islands#violetDotIcon" }),
          );
          setPin({ lat, lon });
        };
        place(ALMATY.lat, ALMATY.lon);
        map.events.add("click", (e) => {
          const coords = e.get("coords");
          place(coords[0], coords[1]);
        });
      })
      .catch((e: unknown) =>
        setMapError(e instanceof Error ? e.message : "Карта недоступна"),
      );
    return () => {
      cancelled = true;
      mapRef.current?.destroy();
      mapRef.current = null;
    };
  }, [hostId]);

  const cities = citiesForCountry(countryCode);

  const submit = () => {
    setSaving(true);
    setError(null);
    startTransition(async () => {
      try {
        await createManagedLocation({
          addressPrimary,
          addressCyrillic,
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
    <SettingsShell title="Новое место" backHref="/app/settings/resources/locations" service="resources">
      <div className="flex flex-col gap-4 px-4 py-4 pb-10">
        {error ? (
          <p className="rounded-[12px] bg-destructive/10 px-3 py-2 text-center text-[12px] font-semibold text-destructive">
            {error}
          </p>
        ) : null}

        <div>
          <p className="mb-2 text-[13px] font-semibold text-ink">Точка на карте</p>
          <p className="mb-2 text-[12px] text-muted">Тапните карту, чтобы поставить пин</p>
          {mapError ? (
            <p className="rounded-[12px] border border-line bg-surface-muted px-3 py-8 text-center text-[13px] text-muted">
              {mapError}
            </p>
          ) : (
            <div
              id={`loc-pick-${hostId}`}
              className="h-[240px] w-full overflow-hidden rounded-[16px] border border-line bg-mint"
            />
          )}
          <p className="mt-1.5 text-[11px] text-muted">
            {pin.lat.toFixed(5)}, {pin.lon.toFixed(5)}
          </p>
        </div>

        <label className="block">
          <span className="mb-1.5 block text-sm font-semibold text-ink">Адрес</span>
          <input
            value={addressPrimary}
            onChange={(e) => setAddressPrimary(e.target.value)}
            placeholder="Основной адрес"
            className="h-12 w-full rounded-[14px] border border-line bg-surface px-4 text-[15px] text-ink outline-none focus:border-svc-resources-ink"
          />
        </label>
        <label className="block">
          <span className="mb-1.5 block text-sm font-semibold text-ink">Дополнительно</span>
          <input
            value={addressCyrillic}
            onChange={(e) => setAddressCyrillic(e.target.value)}
            placeholder="По желанию"
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
          disabled={!addressPrimary.trim() || saving}
          onClick={submit}
        >
          Сохранить
        </AppButton>
      </div>
    </SettingsShell>
  );
}
