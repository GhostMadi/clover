import { createClient } from "@/lib/supabase/client";
import { lsGetJson, lsRemove, lsSetJson } from "@/lib/local-storage";

export type MapMarker = {
  id: string;
  textEmoji: string;
  lat: number;
  lng: number;
  postId?: string | null;
  /** ISO from `list_markers_map.event_time` — for client date filter. */
  eventTime?: string | null;
  /** Server LOD cluster size from `list_markers_map_clusters`. */
  pointCount?: number | null;
};

export type MapMarkersFilter = {
  countryCode: string;
  cityCode: string;
  emoji: string | null;
  tagKeys: string[];
  /** YYYY-MM-DD — client-side filter (как Flutter). */
  dateFrom: string | null;
  dateTo: string | null;
};

export type MapViewport = {
  center: { lat: number; lon: number };
  zoom: number;
};

export const DEFAULT_MAP_FILTER: MapMarkersFilter = {
  countryCode: "kz",
  cityCode: "almaty",
  emoji: null,
  tagKeys: [],
  dateFrom: null,
  dateTo: null,
};

const EARTH_RADIUS_M = 6_371_000;
/** Как Flutter `MapViewportQuery.reloadCenterFraction`. */
const RELOAD_CENTER_FRACTION = 0.4;
/** Как Flutter `MapViewportQuery.reloadZoomDelta`. */
const RELOAD_ZOOM_DELTA = 0.45;
/** Как Flutter `MapViewportQuery.serverClusterMaxZoom`. */
export const SERVER_CLUSTER_MAX_ZOOM = 13;

/** Как `MapViewportQuery.radiusM` в мобилке (ref zoom 12 → 28 km). */
export function radiusMForZoom(zoom: number): number {
  const scale = Math.pow(2, 12 - zoom);
  return Math.min(120_000, Math.max(2_500, 28_000 * scale));
}

/** Как `MapViewportQuery.limit` — плотнее zoom → меньше лимит. */
export function limitForZoom(zoom: number): number {
  if (zoom >= 16) return 200;
  if (zoom >= 14) return 300;
  if (zoom >= 12) return 400;
  return 500;
}

export function useServerClusters(zoom: number): boolean {
  return zoom < SERVER_CLUSTER_MAX_ZOOM;
}

function toRad(deg: number): number {
  return (deg * Math.PI) / 180;
}

export function distanceM(
  a: { lat: number; lon: number },
  b: { lat: number; lon: number },
): number {
  const dLat = toRad(b.lat - a.lat);
  const dLng = toRad(b.lon - a.lon);
  const lat1 = toRad(a.lat);
  const lat2 = toRad(b.lat);
  const h =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(lat1) * Math.cos(lat2) * Math.sin(dLng / 2) * Math.sin(dLng / 2);
  return EARTH_RADIUS_M * 2 * Math.atan2(Math.sqrt(h), Math.sqrt(1 - h));
}

/**
 * Нужен ли новый RPC относительно последнего успешного viewport.
 * Динамика сохраняется; мелкий pan/zoom не бьёт бэк.
 */
export function shouldFetchMapViewport(previous: MapViewport, next: MapViewport): boolean {
  if (Math.abs(next.zoom - previous.zoom) >= RELOAD_ZOOM_DELTA) return true;
  const movedM = distanceM(previous.center, next.center);
  const thresholdM = radiusMForZoom(next.zoom) * RELOAD_CENTER_FRACTION;
  return movedM >= thresholdM;
}

type MapCacheEnvelope = {
  savedAt: string;
  items: MapMarker[];
};

const CACHE_MAX_AGE_MS = 6 * 60 * 60 * 1000;

function filterFingerprint(filter: MapMarkersFilter): string {
  const tags = [...filter.tagKeys].sort().join(",");
  return [
    filter.countryCode,
    filter.cityCode,
    filter.emoji ?? "",
    tags,
    filter.dateFrom ?? "",
    filter.dateTo ?? "",
  ].join("|");
}

/** Ключ дискового кэша — как Flutter MapMarkersLocalCache. */
export function mapMarkersCacheKey(viewport: MapViewport, filter: MapMarkersFilter): string {
  const radius = radiusMForZoom(viewport.zoom);
  let cellDeg = (radius * RELOAD_CENTER_FRACTION) / 111_000;
  if (cellDeg < 0.002) cellDeg = 0.002;
  const latCell = Math.round(viewport.center.lat / cellDeg);
  const lngCell = Math.round(viewport.center.lon / cellDeg);
  const zoomBucket =
    viewport.zoom >= 16 ? 16 : viewport.zoom >= 14 ? 14 : viewport.zoom >= 12 ? 12 : 10;
  const mode = useServerClusters(viewport.zoom) ? "c" : "p";
  return `map_markers_${mode}_z${zoomBucket}_${latCell}_${lngCell}_${filterFingerprint(filter)}`;
}

export function readMapMarkersCache(key: string): MapMarker[] | null {
  const raw = lsGetJson<MapCacheEnvelope>(key);
  if (!raw?.items?.length || !raw.savedAt) return null;
  const saved = Date.parse(raw.savedAt);
  if (!Number.isFinite(saved) || Date.now() - saved > CACHE_MAX_AGE_MS) {
    lsRemove(key);
    return null;
  }
  return raw.items;
}

export function writeMapMarkersCache(key: string, items: MapMarker[]): void {
  lsSetJson(key, {
    savedAt: new Date().toISOString(),
    items,
  } satisfies MapCacheEnvelope);
}

function mapRow(row: Record<string, unknown>): MapMarker {
  const sampleId = row.sample_marker_id ?? row.id;
  const countRaw = row.point_count;
  const eventRaw = row.event_time;
  return {
    id: sampleId == null ? "" : String(sampleId),
    textEmoji: String(row.text_emoji ?? row.sample_emoji ?? "").trim() || "📍",
    lat: Number(row.lat),
    lng: Number(row.lng),
    postId: (row.post_id as string | null | undefined) ?? null,
    eventTime:
      eventRaw == null || eventRaw === ""
        ? null
        : typeof eventRaw === "string"
          ? eventRaw
          : String(eventRaw),
    pointCount: typeof countRaw === "number" ? countRaw : null,
  };
}

/** Как Flutter: даты режем на клиенте после `list_markers_map` (не на clusters). */
export function applyMapDateFilter(
  markers: MapMarker[],
  filter: MapMarkersFilter,
): MapMarker[] {
  if (!filter.dateFrom && !filter.dateTo) return markers;
  return markers.filter((m) => {
    if ((m.pointCount ?? 0) >= 1) return true;
    if (!m.eventTime) return false;
    const t = Date.parse(m.eventTime);
    if (!Number.isFinite(t)) return false;
    if (filter.dateFrom) {
      const from = Date.parse(`${filter.dateFrom}T00:00:00`);
      if (Number.isFinite(from) && t < from) return false;
    }
    if (filter.dateTo) {
      const to = Date.parse(`${filter.dateTo}T23:59:59.999`);
      if (Number.isFinite(to) && t > to) return false;
    }
    return true;
  });
}

/** Маркеры на той же точке (6 знаков) — стопка как Flutter `groupByLocation`. */
export function markersAtLocation(
  all: MapMarker[],
  lat: number,
  lng: number,
): MapMarker[] {
  const key = `${lat.toFixed(6)}_${lng.toFixed(6)}`;
  return all.filter(
    (m) =>
      (m.pointCount ?? 0) < 1 &&
      `${m.lat.toFixed(6)}_${m.lng.toFixed(6)}` === key,
  );
}

export function postIdsFromMarkers(markers: MapMarker[]): string[] {
  const ids: string[] = [];
  const seen = new Set<string>();
  for (const m of markers) {
    const id = m.postId?.trim();
    if (!id || seen.has(id)) continue;
    seen.add(id);
    ids.push(id);
  }
  return ids;
}

async function fetchMapMarkerClusters(
  center: { lat: number; lon: number },
  zoom: number,
  filter: MapMarkersFilter,
): Promise<MapMarker[]> {
  const supabase = createClient();
  const params: Record<string, unknown> = {
    p_lat: center.lat,
    p_lng: center.lon,
    p_radius_m: radiusMForZoom(zoom),
    p_zoom: zoom,
    p_at_time: new Date().toISOString(),
    p_limit: limitForZoom(zoom),
    p_country_code: filter.countryCode || null,
    p_city_code: filter.cityCode || null,
  };
  if (filter.emoji) params.p_emoji = filter.emoji;
  if (filter.tagKeys.length) params.p_tag_keys = filter.tagKeys;

  const { data, error } = await supabase.rpc("list_markers_map_clusters", params);
  if (error) throw error;
  const rows = (data as Record<string, unknown>[] | null) ?? [];
  return rows.map(mapRow);
}

export async function fetchMapMarkers(
  center: { lat: number; lon: number },
  zoom: number,
  filter: MapMarkersFilter = DEFAULT_MAP_FILTER,
): Promise<MapMarker[]> {
  if (useServerClusters(zoom)) {
    return fetchMapMarkerClusters(center, zoom, filter);
  }

  const supabase = createClient();
  const params: Record<string, unknown> = {
    p_lat: center.lat,
    p_lng: center.lon,
    p_radius_m: radiusMForZoom(zoom),
    p_at_time: new Date().toISOString(),
    p_limit: limitForZoom(zoom),
    p_offset: 0,
    p_country_code: filter.countryCode || null,
    p_city_code: filter.cityCode || null,
  };
  if (filter.emoji) params.p_emoji = filter.emoji;
  if (filter.tagKeys.length) params.p_tag_keys = filter.tagKeys;

  const { data, error } = await supabase.rpc("list_markers_map", params);

  if (error) throw error;

  const rows = (data as Record<string, unknown>[] | null) ?? [];
  return applyMapDateFilter(rows.map(mapRow), filter);
}

/** Warm disk cache for N/S/E/W (~0.5 radius). Best-effort, no UI. */
export async function prefetchNeighborMapMarkers(
  viewport: MapViewport,
  filter: MapMarkersFilter,
): Promise<void> {
  const radius = radiusMForZoom(viewport.zoom);
  const stepM = radius * 0.5;
  const latRad = toRad(viewport.center.lat);
  const dLat = stepM / 111_320;
  const dLng = stepM / (111_320 * Math.max(0.2, Math.cos(latRad)));
  const neighbors = [
    { lat: viewport.center.lat + dLat, lon: viewport.center.lon },
    { lat: viewport.center.lat - dLat, lon: viewport.center.lon },
    { lat: viewport.center.lat, lon: viewport.center.lon + dLng },
    { lat: viewport.center.lat, lon: viewport.center.lon - dLng },
  ];

  for (const center of neighbors) {
    const key = mapMarkersCacheKey({ center, zoom: viewport.zoom }, filter);
    const existing = readMapMarkersCache(key);
    if (existing?.length) continue;
    try {
      const list = await fetchMapMarkers(center, viewport.zoom, filter);
      writeMapMarkersCache(key, list);
    } catch {
      // ignore
    }
  }
}
