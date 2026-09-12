"use client";

import { createClient } from "@/lib/supabase/client";
import type { SavedLocation } from "@/features/post-create/lib/post-create-model";

export async function listMyLocations(): Promise<SavedLocation[]> {
  const supabase = createClient();
  const { data, error } = await supabase
    .from("locations")
    .select(
      "id, address_primary, address_cyrillic, latitude, longitude, country_code, city_code, is_active",
    )
    .eq("is_active", true)
    .order("created_at", { ascending: false });
  if (error) throw error;
  const rows = Array.isArray(data) ? data : [];
  return rows.map((r) => {
    const row = r as Record<string, unknown>;
    return {
      id: String(row.id),
      addressPrimary: String(row.address_primary ?? "").trim(),
      addressCyrillic: (row.address_cyrillic as string | null)?.trim() || null,
      latitude: typeof row.latitude === "number" ? row.latitude : Number(row.latitude) || null,
      longitude: typeof row.longitude === "number" ? row.longitude : Number(row.longitude) || null,
      countryCode: (row.country_code as string | null)?.trim() || null,
      cityCode: (row.city_code as string | null)?.trim() || null,
    };
  });
}

/**
 * Быстрый create из композера поста (если снова включим).
 * Тот же контракт, что resources: кириллица обязательна → address_cyrillic;
 * primary = латиница или кириллица.
 */
export async function createLocationQuick(opts: {
  addressCyrillic: string;
  addressLatin?: string | null;
  latitude: number;
  longitude: number;
  countryCode?: string | null;
  cityCode?: string | null;
}): Promise<SavedLocation> {
  const supabase = createClient();
  const {
    data: { session },
  } = await supabase.auth.getSession();
  if (!session?.user.id) throw new Error("Нет сессии");

  const cyr = opts.addressCyrillic.trim();
  if (!cyr) throw new Error("Укажите адрес кириллицей");
  const latin = opts.addressLatin?.trim() || "";

  const insert: Record<string, unknown> = {
    owner_id: session.user.id,
    address_primary: latin || cyr,
    address_cyrillic: cyr,
    latitude: opts.latitude,
    longitude: opts.longitude,
    is_active: true,
  };
  if (opts.countryCode) insert.country_code = opts.countryCode;
  if (opts.cityCode) insert.city_code = opts.cityCode;

  const { data, error } = await supabase
    .from("locations")
    .insert(insert)
    .select(
      "id, address_primary, address_cyrillic, latitude, longitude, country_code, city_code",
    )
    .single();
  if (error) throw error;
  const row = data as Record<string, unknown>;
  return {
    id: String(row.id),
    addressPrimary: String(row.address_primary ?? "").trim(),
    addressCyrillic: (row.address_cyrillic as string | null)?.trim() || null,
    latitude: typeof row.latitude === "number" ? row.latitude : Number(row.latitude) || null,
    longitude: typeof row.longitude === "number" ? row.longitude : Number(row.longitude) || null,
    countryCode: (row.country_code as string | null)?.trim() || null,
    cityCode: (row.city_code as string | null)?.trim() || null,
  };
}
