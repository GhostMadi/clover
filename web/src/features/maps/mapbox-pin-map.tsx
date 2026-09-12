"use client";

import { useEffect, useRef } from "react";
import mapboxgl from "mapbox-gl";
import "mapbox-gl/dist/mapbox-gl.css";
import {
  applyMapboxLightPreset,
  getMapboxToken,
  MAPBOX_STYLE_STANDARD,
  mapboxBasemapConfig,
  subscribeWebTheme,
} from "@/lib/mapbox";

type LngLat = { lat: number; lon: number };

type MapboxPinMapProps = {
  className?: string;
  hostId: string;
  initialCenter: LngLat;
  zoom?: number;
  pin: LngLat;
  /** Радиус геозоны в метрах (круг вокруг pin). */
  geofenceRadiusM?: number;
  onPinChange: (pin: LngLat) => void;
  onReadyError?: (message: string) => void;
};

function circlePolygon(center: LngLat, radiusM: number, steps = 64): GeoJSON.Feature<GeoJSON.Polygon> {
  const coords: [number, number][] = [];
  const latRad = (center.lat * Math.PI) / 180;
  const metersPerDegLat = 111_320;
  const metersPerDegLon = 111_320 * Math.cos(latRad);
  for (let i = 0; i <= steps; i++) {
    const a = (i / steps) * Math.PI * 2;
    const dLat = (Math.sin(a) * radiusM) / metersPerDegLat;
    const dLon = (Math.cos(a) * radiusM) / metersPerDegLon;
    coords.push([center.lon + dLon, center.lat + dLat]);
  }
  return {
    type: "Feature",
    properties: {},
    geometry: { type: "Polygon", coordinates: [coords] },
  };
}

function ensureGeofenceLayers(
  map: mapboxgl.Map,
  hostId: string,
  pin: LngLat,
  radiusM: number | undefined,
) {
  if (radiusM == null || radiusM <= 0) return;
  const sourceId = `geo-${hostId}`;
  const fillId = `geo-fill-${hostId}`;
  const lineId = `geo-line-${hostId}`;
  const data = circlePolygon(pin, radiusM);
  const existing = map.getSource(sourceId) as mapboxgl.GeoJSONSource | undefined;
  if (existing) {
    existing.setData(data);
    return;
  }
  map.addSource(sourceId, { type: "geojson", data });
  map.addLayer({
    id: fillId,
    type: "fill",
    source: sourceId,
    paint: { "fill-color": "#5b9bd5", "fill-opacity": 0.2 },
  });
  map.addLayer({
    id: lineId,
    type: "line",
    source: sourceId,
    paint: { "line-color": "#5b9bd5", "line-width": 2 },
  });
}

/** Кликовая карта с пином (и опционально геозоной) на Mapbox Standard. */
export function MapboxPinMap({
  className = "",
  hostId,
  initialCenter,
  zoom = 12,
  pin,
  geofenceRadiusM,
  onPinChange,
  onReadyError,
}: MapboxPinMapProps) {
  const containerRef = useRef<HTMLDivElement | null>(null);
  const mapRef = useRef<mapboxgl.Map | null>(null);
  const markerRef = useRef<mapboxgl.Marker | null>(null);
  const pinRef = useRef(pin);
  const radiusRef = useRef(geofenceRadiusM);
  const onPinChangeRef = useRef(onPinChange);
  pinRef.current = pin;
  radiusRef.current = geofenceRadiusM;
  onPinChangeRef.current = onPinChange;
  const token = getMapboxToken();

  useEffect(() => {
    if (!token) {
      onReadyError?.("Нет ключа карты");
      return;
    }
    if (!containerRef.current || mapRef.current) return;

    mapboxgl.accessToken = token;
    const map = new mapboxgl.Map({
      container: containerRef.current,
      style: MAPBOX_STYLE_STANDARD,
      center: [initialCenter.lon, initialCenter.lat],
      zoom,
      attributionControl: false,
      config: mapboxBasemapConfig(),
    } as mapboxgl.MapOptions);

    const marker = new mapboxgl.Marker({ color: "#5B8C5A" })
      .setLngLat([pin.lon, pin.lat])
      .addTo(map);
    markerRef.current = marker;

    const paintGeofence = () => {
      ensureGeofenceLayers(map, hostId, pinRef.current, radiusRef.current);
    };

    map.on("load", () => {
      mapRef.current = map;
      const logo = map.getContainer().querySelector(".mapboxgl-ctrl-logo");
      if (logo instanceof HTMLElement) logo.style.display = "none";
      paintGeofence();
    });
    map.on("style.load", paintGeofence);

    map.on("click", (e) => {
      onPinChangeRef.current({ lat: e.lngLat.lat, lon: e.lngLat.lng });
    });

    map.on("error", () => onReadyError?.("Карта недоступна"));

    const unsubTheme = subscribeWebTheme((dark) => {
      applyMapboxLightPreset(map, dark);
    });

    return () => {
      unsubTheme();
      markerRef.current?.remove();
      markerRef.current = null;
      map.remove();
      mapRef.current = null;
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps -- mount once
  }, [token, hostId]);

  useEffect(() => {
    const map = mapRef.current;
    const marker = markerRef.current;
    if (!map || !marker) return;
    marker.setLngLat([pin.lon, pin.lat]);
    map.easeTo({ center: [pin.lon, pin.lat], duration: 150 });
    ensureGeofenceLayers(map, hostId, pin, geofenceRadiusM);
  }, [pin, geofenceRadiusM, hostId]);

  if (!token) {
    return (
      <div className={`flex items-center justify-center bg-mint/40 text-sm text-muted ${className}`}>
        Добавь NEXT_PUBLIC_MAPBOX_ACCESS_TOKEN
      </div>
    );
  }

  return <div ref={containerRef} className={className} />;
}
