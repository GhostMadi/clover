"use client";

import { useEffect, useRef, useState } from "react";
import mapboxgl from "mapbox-gl";
import "mapbox-gl/dist/mapbox-gl.css";
import type { MapMarker } from "@/features/cabinet/lib/map-markers";
import { SERVER_CLUSTER_MAX_ZOOM } from "@/features/cabinet/lib/map-markers";
import {
  applyMapboxLightPreset,
  getMapboxToken,
  isWebDarkTheme,
  MAPBOX_STYLE_STANDARD,
  mapboxBasemapConfig,
  subscribeWebTheme,
} from "@/lib/mapbox";

const ALMATY = { lat: 43.238949, lon: 76.889709 };
const SOURCE_ID = "clover-feed";
const LAYER_CLUSTERS = "clover-feed-clusters";
const LAYER_CLUSTER_COUNT = "clover-feed-cluster-count";
const LAYER_POINTS = "clover-feed-points";
const LAYER_POINT_BG = "clover-feed-point-bg";

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

function isServerClusterMode(markers: MapMarker[]): boolean {
  return markers.some((m) => (m.pointCount ?? 0) >= 1);
}

/** Points / stacks for GeoJSON (server clusters use HTML markers on web). */
function pointsToGeoJson(markers: MapMarker[]): GeoJSON.FeatureCollection {
  const byKey = new Map<string, MapMarker[]>();
  for (const m of markers) {
    if ((m.pointCount ?? 0) >= 1) continue;
    const key = `${m.lat.toFixed(6)}_${m.lng.toFixed(6)}`;
    const list = byKey.get(key) ?? [];
    list.push(m);
    byKey.set(key, list);
  }

  const features: GeoJSON.Feature[] = [];
  for (const [, group] of byKey) {
    const first = group[0]!;
    if (group.length === 1) {
      features.push({
        type: "Feature",
        id: first.id,
        properties: {
          kind: "marker",
          id: first.id,
          emoji: first.textEmoji,
          postId: first.postId ?? null,
        },
        geometry: { type: "Point", coordinates: [first.lng, first.lat] },
      });
    } else {
      features.push({
        type: "Feature",
        id: first.id,
        properties: {
          kind: "stack",
          id: first.id,
          emoji: first.textEmoji,
          ids: group.map((g) => g.id).join(","),
          postId: first.postId ?? null,
          stack_count: group.length,
        },
        geometry: { type: "Point", coordinates: [first.lng, first.lat] },
      });
    }
  }

  return { type: "FeatureCollection", features };
}

/** HTML badge: emoji in center + count chip — web can render emoji natively (faster than Flutter PNG). */
function createClusterBadgeEl(emoji: string, count: number, dark: boolean): HTMLDivElement {
  const root = document.createElement("div");
  root.style.cssText = "position:relative;width:44px;height:44px;cursor:pointer;";

  const badge = document.createElement("div");
  badge.style.cssText = [
    "width:44px",
    "height:44px",
    "border-radius:999px",
    `background:${dark ? "#fff" : "#0D0D0D"}`,
    "border:3px solid #8BC34A",
    "box-shadow:0 2px 8px rgba(0,0,0,.28)",
    "display:flex",
    "align-items:center",
    "justify-content:center",
    "font-size:22px",
    "line-height:1",
    "user-select:none",
  ].join(";");
  badge.textContent = emoji.trim() || "📍";
  root.appendChild(badge);

  if (count > 1) {
    const chip = document.createElement("div");
    chip.style.cssText = [
      "position:absolute",
      "top:-4px",
      "right:-6px",
      "min-width:20px",
      "height:20px",
      "padding:0 5px",
      "border-radius:999px",
      "background:#8BC34A",
      "border:2px solid #fff",
      "color:#fff",
      "font:700 11px/16px system-ui,sans-serif",
      "display:flex",
      "align-items:center",
      "justify-content:center",
      "box-shadow:0 1px 4px rgba(0,0,0,.25)",
    ].join(";");
    chip.textContent = count > 99 ? "99+" : String(count);
    root.appendChild(chip);
  }

  return root;
}

function ensurePointLayers(map: mapboxgl.Map, dark: boolean) {
  for (const id of [LAYER_CLUSTER_COUNT, LAYER_CLUSTERS, LAYER_POINTS, LAYER_POINT_BG]) {
    if (map.getLayer(id)) map.removeLayer(id);
  }
  if (map.getSource(SOURCE_ID)) map.removeSource(SOURCE_ID);

  map.addSource(SOURCE_ID, {
    type: "geojson",
    data: { type: "FeatureCollection", features: [] },
    cluster: true,
    clusterMaxZoom: 14,
    clusterRadius: 50,
  });

  // Client proximity clusters (no sample emoji) — soft circle + count.
  map.addLayer({
    id: LAYER_CLUSTERS,
    type: "circle",
    source: SOURCE_ID,
    filter: ["has", "point_count"],
    paint: {
      "circle-color": dark ? "#ffffff" : "#0D0D0D",
      "circle-radius": ["step", ["get", "point_count"], 18, 25, 24, 100, 30],
      "circle-stroke-width": 3,
      "circle-stroke-color": "#8BC34A",
      "circle-emissive-strength": 1,
    },
  });
  map.addLayer({
    id: LAYER_CLUSTER_COUNT,
    type: "symbol",
    source: SOURCE_ID,
    filter: ["has", "point_count"],
    layout: {
      "text-field": ["get", "point_count_abbreviated"],
      "text-size": 12,
      "text-allow-overlap": true,
    },
    paint: {
      "text-color": dark ? "#0D0D0D" : "#ffffff",
      "text-emissive-strength": 1,
    },
  });

  // Unclustered points: badge ring + emoji (browser text renders emoji fine).
  map.addLayer({
    id: LAYER_POINT_BG,
    type: "circle",
    source: SOURCE_ID,
    filter: [
      "all",
      ["!", ["has", "point_count"]],
      ["any", ["==", ["get", "kind"], "marker"], ["==", ["get", "kind"], "stack"]],
    ],
    paint: {
      "circle-color": dark ? "#ffffff" : "#0D0D0D",
      "circle-radius": 16,
      "circle-stroke-width": 3,
      "circle-stroke-color": "#8BC34A",
      "circle-emissive-strength": 1,
    },
  });
  map.addLayer({
    id: LAYER_POINTS,
    type: "symbol",
    source: SOURCE_ID,
    filter: [
      "all",
      ["!", ["has", "point_count"]],
      ["any", ["==", ["get", "kind"], "marker"], ["==", ["get", "kind"], "stack"]],
    ],
    layout: {
      "text-field": ["get", "emoji"],
      "text-size": 20,
      "text-allow-overlap": true,
      "text-ignore-placement": true,
    },
  });
}

function clearPointLayers(map: mapboxgl.Map) {
  for (const id of [LAYER_CLUSTER_COUNT, LAYER_CLUSTERS, LAYER_POINTS, LAYER_POINT_BG]) {
    if (map.getLayer(id)) map.removeLayer(id);
  }
  if (map.getSource(SOURCE_ID)) map.removeSource(SOURCE_ID);
}

/** Полноэкранная Mapbox Standard карта: server clusters = HTML emoji, points = GeoJSON. */
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
  const htmlMarkersRef = useRef<mapboxgl.Marker[]>([]);
  const markersRef = useRef(markers);
  markersRef.current = markers;
  const darkRef = useRef(isWebDarkTheme());
  const onViewportRef = useRef(onViewportChange);
  const onMarkerClickRef = useRef(onMarkerClick);
  onViewportRef.current = onViewportChange;
  onMarkerClickRef.current = onMarkerClick;
  const [error, setError] = useState<string | null>(null);
  const [ready, setReady] = useState(false);
  const token = getMapboxToken();

  const syncHtmlClusters = (map: mapboxgl.Map, list: MapMarker[], dark: boolean) => {
    for (const m of htmlMarkersRef.current) m.remove();
    htmlMarkersRef.current = [];

    const clusters = list.filter((m) => (m.pointCount ?? 0) >= 1);
    for (const c of clusters) {
      const el = createClusterBadgeEl(c.textEmoji, c.pointCount ?? 1, dark);
      el.addEventListener("click", (ev) => {
        ev.stopPropagation();
        map.easeTo({
          center: [c.lng, c.lat],
          zoom: Math.max(map.getZoom() + 2, SERVER_CLUSTER_MAX_ZOOM),
        });
      });
      const marker = new mapboxgl.Marker({ element: el, anchor: "center" })
        .setLngLat([c.lng, c.lat])
        .addTo(map);
      htmlMarkersRef.current.push(marker);
    }
  };

  const syncFeed = (map: mapboxgl.Map, list: MapMarker[], dark: boolean) => {
    const serverMode = isServerClusterMode(list);
    if (serverMode) {
      clearPointLayers(map);
      syncHtmlClusters(map, list, dark);
      return;
    }

    for (const m of htmlMarkersRef.current) m.remove();
    htmlMarkersRef.current = [];

    if (!map.getSource(SOURCE_ID)) {
      ensurePointLayers(map, dark);
    }
    const source = map.getSource(SOURCE_ID) as mapboxgl.GeoJSONSource | undefined;
    source?.setData(pointsToGeoJson(list));
  };

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
      const logo = map.getContainer().querySelector(".mapboxgl-ctrl-logo");
      if (logo instanceof HTMLElement) logo.style.display = "none";

      darkRef.current = isWebDarkTheme();
      syncFeed(map, markersRef.current, darkRef.current);

      map.on("click", LAYER_CLUSTERS, (e) => {
        const features = map.queryRenderedFeatures(e.point, { layers: [LAYER_CLUSTERS] });
        const feature = features[0];
        if (!feature || feature.geometry.type !== "Point") return;
        const clusterId = feature.properties?.cluster_id as number | undefined;
        const source = map.getSource(SOURCE_ID) as mapboxgl.GeoJSONSource | undefined;
        if (clusterId == null || !source) return;
        source.getClusterExpansionZoom(clusterId, (err, zoomTo) => {
          if (err || zoomTo == null) return;
          const coords = (feature.geometry as GeoJSON.Point).coordinates as [number, number];
          map.easeTo({ center: coords, zoom: zoomTo });
        });
      });

      map.on("click", LAYER_POINTS, (e) => {
        const feature = e.features?.[0];
        if (!feature) return;
        const id = String(feature.properties?.id ?? "");
        const postId = (feature.properties?.postId as string | null | undefined) ?? null;
        const emoji = String(feature.properties?.emoji ?? "📍");
        const coords = (feature.geometry as GeoJSON.Point).coordinates;
        onMarkerClickRef.current?.({
          id,
          textEmoji: emoji,
          lat: coords[1]!,
          lng: coords[0]!,
          postId,
        });
      });

      for (const layerId of [LAYER_CLUSTERS, LAYER_POINTS]) {
        map.on("mouseenter", layerId, () => {
          map.getCanvas().style.cursor = "pointer";
        });
        map.on("mouseleave", layerId, () => {
          map.getCanvas().style.cursor = "";
        });
      }

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
      darkRef.current = dark;
      applyMapboxLightPreset(map, dark);
      // Rebuild layers / HTML badges for contrast fill.
      syncFeed(map, markersRef.current, dark);
    });

    return () => {
      cancelled = true;
      unsubTheme();
      clearTimeout(debounce);
      for (const m of htmlMarkersRef.current) m.remove();
      htmlMarkersRef.current = [];
      map.remove();
      mapRef.current = null;
      setReady(false);
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps -- initial center/zoom only
  }, [token]);

  useEffect(() => {
    const map = mapRef.current;
    if (!ready || !map) return;
    syncFeed(map, markers, darkRef.current);
    // eslint-disable-next-line react-hooks/exhaustive-deps -- syncFeed is stable enough via refs
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
