"use client";

import { useEffect, useRef, useState } from "react";
import mapboxgl from "mapbox-gl";
import "mapbox-gl/dist/mapbox-gl.css";
import type { MapMarker } from "@/features/cabinet/lib/map-markers";
import {
  applyMapboxLightPreset,
  getMapboxToken,
  MAPBOX_STYLE_STANDARD,
  mapboxBasemapConfig,
  subscribeWebTheme,
} from "@/lib/mapbox";

const ALMATY = { lat: 43.238949, lon: 76.889709 };

type MapboxMapProps = {
  className?: string;
  center?: { lat: number; lon: number };
  zoom?: number;
  markers?: MapMarker[];
  onViewportChange?: (center: { lat: number; lon: number }, zoom: number) => void;
  onMarkerClick?: (marker: MapMarker) => void;
  /** Внешний запрос «моя геолокация» — карта перемещается сюда. */
  flyTo?: { lat: number; lon: number; zoom?: number; nonce?: number } | null;
};

/** Полноэкранная Mapbox Standard карта с emoji-маркерами ивентов. */
export function MapboxMap({
  className = "",
  center = ALMATY,
  zoom = 12,
  markers = [],
  onViewportChange,
  onMarkerClick,
  flyTo = null,
}: MapboxMapProps) {
  const containerRef = useRef<HTMLDivElement | null>(null);
  const mapRef = useRef<mapboxgl.Map | null>(null);
  const markersRef = useRef<mapboxgl.Marker[]>([]);
  const onViewportRef = useRef(onViewportChange);
  const onMarkerClickRef = useRef(onMarkerClick);
  onViewportRef.current = onViewportChange;
  onMarkerClickRef.current = onMarkerClick;
  const [error, setError] = useState<string | null>(null);
  const [ready, setReady] = useState(false);
  const token = getMapboxToken();

  useEffect(() => {
    if (!token) {
      setError("missing-key");
      return;
    }
    if (!containerRef.current || mapRef.current) return;

    let cancelled = false;
    let debounce: ReturnType<typeof setTimeout> | undefined;

    mapboxgl.accessToken = token;
    const map = new mapboxgl.Map({
      container: containerRef.current,
      style: MAPBOX_STYLE_STANDARD,
      center: [center.lon, center.lat],
      zoom,
      attributionControl: false,
      logoPosition: "bottom-left",
      config: mapboxBasemapConfig(),
    } as mapboxgl.MapOptions);

    const emitViewport = () => {
      clearTimeout(debounce);
      debounce = setTimeout(() => {
        const c = map.getCenter();
        onViewportRef.current?.({ lat: c.lat, lon: c.lng }, map.getZoom());
      }, 450);
    };

    map.on("load", () => {
      if (cancelled) return;
      // Спрятать логотип Mapbox (если остался в DOM).
      const logo = map.getContainer().querySelector(".mapboxgl-ctrl-logo");
      if (logo instanceof HTMLElement) logo.style.display = "none";
      mapRef.current = map;
      setReady(true);
      onViewportRef.current?.({ lat: center.lat, lon: center.lon }, zoom);
    });
    map.on("moveend", emitViewport);
    map.on("error", () => {
      if (!cancelled) setError("load-failed");
    });

    const unsubTheme = subscribeWebTheme((dark) => {
      if (cancelled || !mapRef.current) return;
      applyMapboxLightPreset(map, dark);
    });

    return () => {
      cancelled = true;
      unsubTheme();
      clearTimeout(debounce);
      for (const m of markersRef.current) m.remove();
      markersRef.current = [];
      map.remove();
      mapRef.current = null;
      setReady(false);
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps -- initial center/zoom only
  }, [token]);

  useEffect(() => {
    const map = mapRef.current;
    if (!ready || !map) return;

    for (const m of markersRef.current) m.remove();
    markersRef.current = [];

    for (const m of markers) {
      const el = document.createElement("button");
      el.type = "button";
      el.textContent = m.textEmoji;
      el.setAttribute("aria-label", m.textEmoji);
      el.style.cssText = `
        transform: translateY(-4px);
        display: flex;
        align-items: center;
        justify-content: center;
        min-width: 40px;
        height: 40px;
        padding: 0 10px;
        border-radius: 999px;
        background: var(--surface);
        border: 2px solid var(--brand);
        box-shadow: var(--elevate-md);
        font-size: 20px;
        line-height: 1;
        cursor: pointer;
      `;
      el.addEventListener("click", (e) => {
        e.stopPropagation();
        onMarkerClickRef.current?.(m);
      });
      const marker = new mapboxgl.Marker({ element: el, anchor: "bottom" })
        .setLngLat([m.lng, m.lat])
        .addTo(map);
      markersRef.current.push(marker);
    }
  }, [markers, ready]);

  useEffect(() => {
    if (!ready || !flyTo || !mapRef.current) return;
    mapRef.current.flyTo({
      center: [flyTo.lon, flyTo.lat],
      zoom: flyTo.zoom ?? mapRef.current.getZoom(),
      duration: 400,
    });
  }, [flyTo, ready]);

  if (!token || error === "missing-key") {
    return (
      <div className={`flex flex-col items-center justify-center gap-3 bg-mint/50 p-8 text-center ${className}`}>
        <p className="font-semibold text-ink">Карта</p>
        <p className="max-w-sm text-sm text-muted">
          Добавь <code className="text-ink">NEXT_PUBLIC_MAPBOX_ACCESS_TOKEN</code> в{" "}
          <code className="text-ink">web/.env.local</code>
        </p>
      </div>
    );
  }

  if (error === "load-failed") {
    return (
      <div className={`flex items-center justify-center bg-surface p-8 ${className}`}>
        <p className="text-sm text-muted">Не удалось загрузить карту. Проверь токен и URL-ограничения.</p>
      </div>
    );
  }

  return <div ref={containerRef} className={`bg-mint ${className}`} />;
}
