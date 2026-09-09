import { createClient } from "@/lib/supabase/client";
import { lsGetJson, lsRemove, lsSetJson } from "@/lib/local-storage";

export type MapMarker = {
  id: string;
  textEmoji: string;
  lat: number;
  lng: number;
  postId?: string | null;
};

export type MapMarkersFilter = {
  countryCode: string;
  cityCode: string;
  emoji: string | null;
  tagKeys: string[];
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
};

const EARTH_RADIUS_M = 6_371_000;
/** Как Flutter `MapViewportQuery.reloadCenterFraction`. */
const RELOAD_CENTER_FRACTION = 0.4;
/** Как Flutter `MapViewportQuery.reloadZoomDelta`. */
const RELOAD_ZOOM_DELTA = 0.45;

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
  return [filter.countryCode, filter.cityCode, filter.emoji ?? "", tags].join("|");
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
  return `map_markers_z${zoomBucket}_${latCell}_${lngCell}_${filterFingerprint(filter)}`;
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

export async function fetchMapMarkers(
  center: { lat: number; lon: number },
  zoom: number,
  filter: MapMarkersFilter = DEFAULT_MAP_FILTER,
): Promise<MapMarker[]> {
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
  return rows.map((row) => ({
    id: String(row.id),
    textEmoji: String(row.text_emoji ?? "").trim() || "📍",
    lat: Number(row.lat),
    lng: Number(row.lng),
    postId: (row.post_id as string | null | undefined) ?? null,
  }));
}
