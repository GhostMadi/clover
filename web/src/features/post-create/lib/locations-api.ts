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

export async function createLocationQuick(opts: {
  addressPrimary: string;
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

  const insert: Record<string, unknown> = {
    owner_id: session.user.id,
    address_primary: opts.addressPrimary.trim(),
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
