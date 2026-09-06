"use client";

import { useRouter } from "next/navigation";
import { useEffect, useId, useRef, useState } from "react";
import { AppButton } from "@/components/shared/app-button";
import { AppButtonLink } from "@/components/shared/app-button";
import { AttendanceListShimmer } from "@/features/attendance/components/attendance-shimmers";
import {
  getAdminWorkplace,
  updateGeofence,
} from "@/features/attendance/lib/attendance-api";
import { hasGeofenceCenter } from "@/features/attendance/lib/attendance-model";
import { SettingsShell } from "@/features/settings/components/settings-shell";

const ALMATY = { lat: 43.238949, lon: 76.889709 };

type MapHandle = {
  destroy: () => void;
  setCenter: (coords: number[], zoom?: number, opts?: object) => void;
  events: {
    add: (name: string, cb: (e: { get: (k: string) => number[] }) => void) => void;
  };
  geoObjects: { removeAll: () => void; add: (obj: unknown) => void };
};

type YmapsNs = {
  ready: (cb: () => void) => void;
  Map: new (el: HTMLElement, opts: object) => MapHandle;
  Placemark: new (coords: number[], props?: object, opts?: object) => unknown;
  Circle: new (
    geometry: [number[], number],
    props?: object,
    opts?: object,
  ) => unknown;
};

function getYmaps(): YmapsNs | undefined {
  return (window as unknown as { ymaps?: YmapsNs }).ymaps;
}

function loadYmaps(apiKey: string): Promise<YmapsNs> {
  const existing = getYmaps();
  if (existing) {
    return new Promise((resolve) => existing.ready(() => resolve(existing)));
  }
  const scriptExisting = document.querySelector<HTMLScriptElement>(
    "script[data-yandex-maps]",
  );
  if (scriptExisting) {
    return new Promise((resolve, reject) => {
      scriptExisting.addEventListener("load", () => {
        const y = getYmaps();
        if (!y) reject(new Error("Карта не загрузилась"));
        else y.ready(() => resolve(y));
      });
      scriptExisting.addEventListener("error", () =>
        reject(new Error("Карта не загрузилась")),
      );
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

function zoomForRadius(radiusM: number): number {
  if (radiusM <= 75) return 16.5;
  if (radiusM <= 150) return 15.5;
  return 14.5;
}

export function AttendanceGeofenceView({ workplaceId }: { workplaceId: string }) {
  const router = useRouter();
  const hostId = useId().replace(/:/g, "");
  const mapRef = useRef<MapHandle | null>(null);
  const ymapsRef = useRef<YmapsNs | null>(null);
  const [loading, setLoading] = useState(true);
  const [loadError, setLoadError] = useState<string | null>(null);
  const [mapError, setMapError] = useState<string | null>(null);
  const [pin, setPin] = useState(ALMATY);
  const [radius, setRadius] = useState(150);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const back = `/app/settings/attendance/w/${workplaceId}/settings`;

  useEffect(() => {
    let cancelled = false;
    void getAdminWorkplace(workplaceId)
      .then((w) => {
        if (cancelled) return;
        if (!w) {
          setLoadError("Компания не найдена или нет прав admin");
          setLoading(false);
          return;
        }
        if (hasGeofenceCenter(w)) {
          setPin({ lat: w.latitude!, lon: w.longitude! });
        }
        setRadius(w.geofenceRadiusM || 150);
        setLoading(false);
      })
      .catch((e: unknown) => {
        if (cancelled) return;
        setLoadError(e instanceof Error ? e.message : "Не удалось загрузить");
        setLoading(false);
      });
    return () => {
      cancelled = true;
    };
  }, [workplaceId]);

  useEffect(() => {
    if (loading || loadError) return;
    const key = process.env.NEXT_PUBLIC_YANDEX_MAPS_API_KEY?.trim();
    if (!key) {
      setMapError("Нет ключа карты");
      return;
    }
    let cancelled = false;
    void loadYmaps(key)
      .then((ymaps) => {
        if (cancelled) return;
        ymapsRef.current = ymaps;
        const el = document.getElementById(`att-geo-${hostId}`);
        if (!el) return;
        const map = new ymaps.Map(el, {
          center: [pin.lat, pin.lon],
          zoom: zoomForRadius(radius),
          controls: ["zoomControl", "geolocationControl"],
        });
        mapRef.current = map;

        const paint = (lat: number, lon: number, r: number) => {
          map.geoObjects.removeAll();
          map.geoObjects.add(
            new ymaps.Circle(
              [[lat, lon], r],
              {},
              {
                fillColor: "#5b9bd533",
                strokeColor: "#5b9bd5",
                strokeWidth: 2,
              },
            ),
          );
          map.geoObjects.add(
            new ymaps.Placemark(
              [lat, lon],
              {},
              { preset: "islands#blueDotIcon" },
            ),
          );
          map.setCenter([lat, lon], zoomForRadius(r), { duration: 200 });
        };

        paint(pin.lat, pin.lon, radius);
        map.events.add("click", (e) => {
          const coords = e.get("coords");
          const next = { lat: coords[0], lon: coords[1] };
          setPin(next);
          paint(next.lat, next.lon, radius);
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
    // init map once after workplace load
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [loading, loadError, hostId]);

  useEffect(() => {
    const map = mapRef.current;
    const ymaps = ymapsRef.current;
    if (!map || !ymaps) return;
    map.geoObjects.removeAll();
    map.geoObjects.add(
      new ymaps.Circle(
        [[pin.lat, pin.lon], radius],
        {},
        {
          fillColor: "#5b9bd533",
          strokeColor: "#5b9bd5",
          strokeWidth: 2,
        },
      ),
    );
    map.geoObjects.add(
      new ymaps.Placemark([pin.lat, pin.lon], {}, { preset: "islands#blueDotIcon" }),
    );
    map.setCenter([pin.lat, pin.lon], zoomForRadius(radius), { duration: 150 });
  }, [pin, radius]);

  if (loading) {
    return (
      <SettingsShell title="Геозона" backHref={back} service="attendance">
        <div className="px-4 py-5">
          <AttendanceListShimmer rows={3} />
        </div>
      </SettingsShell>
    );
  }

  if (loadError) {
    return (
      <SettingsShell title="Геозона" backHref={back} service="attendance">
        <div className="space-y-3 px-4 py-5">
          <p className="text-[14px] text-error">{loadError}</p>
          <AppButtonLink href={back} service="attendance">
            Назад
          </AppButtonLink>
        </div>
      </SettingsShell>
    );
  }

  const save = async () => {
    setSaving(true);
    setError(null);
    try {
      await updateGeofence({
        workplaceId,
        lat: pin.lat,
        lng: pin.lon,
        geofenceRadiusM: radius,
      });
      router.push(back);
      router.refresh();
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : "Не удалось сохранить");
      setSaving(false);
    }
  };

  return (
    <SettingsShell title="Геозона" backHref={back} service="attendance">
      <div className="flex flex-col gap-4 px-4 py-4 pb-10">
        <p className="text-[13px] text-muted">
          Тапните карту, чтобы поставить центр. Радиус — зона, где можно
          отметиться.
        </p>

        {mapError ? (
          <p className="rounded-[12px] border border-line bg-surface-muted px-3 py-8 text-center text-[13px] text-muted">
            {mapError}
          </p>
        ) : (
          <div
            id={`att-geo-${hostId}`}
            className="h-[280px] w-full overflow-hidden rounded-[16px] border border-line bg-mint"
          />
        )}

        <p className="text-[11px] text-muted">
          {pin.lat.toFixed(5)}, {pin.lon.toFixed(5)}
        </p>

        <label className="block">
          <div className="mb-2 flex items-center justify-between gap-2">
            <span className="text-[13px] font-semibold text-ink">Радиус</span>
            <span className="text-[13px] font-bold text-svc-attendance-ink">
              {radius} м
            </span>
          </div>
          <input
            type="range"
            min={50}
            max={300}
            step={10}
            value={radius}
            onChange={(e) => setRadius(Number(e.target.value))}
            className="w-full accent-[var(--svc-attendance-ink)]"
          />
          <div className="mt-1 flex justify-between text-[11px] text-muted">
            <span>50 м</span>
            <span>300 м</span>
          </div>
        </label>

        {error ? <p className="text-[13px] text-error">{error}</p> : null}

        <AppButton
          type="button"
          service="attendance"
          loading={saving}
          onClick={() => void save()}
        >
          Сохранить
        </AppButton>
      </div>
    </SettingsShell>
  );
}
