import { createClient } from "@/lib/supabase/client";

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

export const DEFAULT_MAP_FILTER: MapMarkersFilter = {
  countryCode: "kz",
  cityCode: "almaty",
  emoji: null,
  tagKeys: [],
};

/** Как `MapViewportQuery.radiusM` в мобилке (ref zoom 12 → 28 km). */
export function radiusMForZoom(zoom: number): number {
  const scale = Math.pow(2, 12 - zoom);
  return Math.min(120_000, Math.max(2_500, 28_000 * scale));
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
    p_limit: 120,
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
