"use client";

import { createClient } from "@/lib/supabase/client";
import type { SavedLocation } from "@/features/post-create/lib/post-create-model";

export type ManagedLocation = SavedLocation & {
  isActive: boolean;
};

function mapRow(row: Record<string, unknown>): ManagedLocation {
  return {
    id: String(row.id),
    addressPrimary: String(row.address_primary ?? "").trim(),
    addressCyrillic: (row.address_cyrillic as string | null)?.trim() || null,
    latitude: typeof row.latitude === "number" ? row.latitude : Number(row.latitude) || null,
    longitude: typeof row.longitude === "number" ? row.longitude : Number(row.longitude) || null,
    countryCode: (row.country_code as string | null)?.trim() || null,
    cityCode: (row.city_code as string | null)?.trim() || null,
    isActive: row.is_active !== false,
  };
}

const SELECT =
  "id, address_primary, address_cyrillic, latitude, longitude, country_code, city_code, is_active";

/** Все места владельца (активные и нет) — для справочника Ресурсов. */
export async function listMyLocationsAll(): Promise<ManagedLocation[]> {
  const supabase = createClient();
  const { data, error } = await supabase
    .from("locations")
    .select(SELECT)
    .order("created_at", { ascending: false });
  if (error) throw error;
  return (data ?? []).map((r) => mapRow(r as Record<string, unknown>));
}

export async function getMyLocation(id: string): Promise<ManagedLocation | null> {
  const supabase = createClient();
  const { data, error } = await supabase
    .from("locations")
    .select(SELECT)
    .eq("id", id)
    .maybeSingle();
  if (error) throw error;
  if (!data) return null;
  return mapRow(data as Record<string, unknown>);
}

export async function createManagedLocation(opts: {
  /** Обязательный адрес кириллицей. */
  addressCyrillic: string;
  /** Латиница — по желанию; если пусто, в primary уходит кириллица. */
  addressLatin?: string | null;
  latitude: number;
  longitude: number;
  countryCode?: string | null;
  cityCode?: string | null;
}): Promise<ManagedLocation> {
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
    // primary — латиница, если есть; иначе кириллица (колонка NOT NULL / обязательна в продукте)
    address_primary: latin || cyr,
    address_cyrillic: cyr,
    latitude: opts.latitude,
    longitude: opts.longitude,
    is_active: true,
  };
  if (opts.countryCode && opts.cityCode) {
    insert.country_code = opts.countryCode;
    insert.city_code = opts.cityCode;
  }

  const { data, error } = await supabase
    .from("locations")
    .insert(insert)
    .select(SELECT)
    .single();
  if (error) throw error;
  return mapRow(data as Record<string, unknown>);
}

export async function updateManagedLocation(opts: {
  id: string;
  addressCyrillic?: string;
  addressLatin?: string | null;
  clearAddressLatin?: boolean;
  countryCode?: string | null;
  cityCode?: string | null;
  clearGeoBinding?: boolean;
  isActive?: boolean;
}): Promise<ManagedLocation> {
  const supabase = createClient();
  const patch: Record<string, unknown> = {};
  if (opts.addressCyrillic != null) {
    const cyr = opts.addressCyrillic.trim();
    if (!cyr) throw new Error("Укажите адрес кириллицей");
    const latin = opts.clearAddressLatin ? "" : opts.addressLatin?.trim() || "";
    patch.address_cyrillic = cyr;
    patch.address_primary = latin || cyr;
  }
  if (opts.clearGeoBinding) {
    patch.country_code = null;
    patch.city_code = null;
  } else if (opts.countryCode !== undefined || opts.cityCode !== undefined) {
    const country = opts.countryCode?.trim() || null;
    const city = opts.cityCode?.trim() || null;
    if ((country && !city) || (!country && city)) {
      throw new Error("Страна и город — оба или сброс");
    }
    patch.country_code = country;
    patch.city_code = city;
  }
  if (opts.isActive !== undefined) patch.is_active = opts.isActive;

  const { data, error } = await supabase
    .from("locations")
    .update(patch)
    .eq("id", opts.id)
    .select(SELECT)
    .single();
  if (error) throw error;
  return mapRow(data as Record<string, unknown>);
}

export async function deleteManagedLocation(id: string): Promise<void> {
  const supabase = createClient();
  const { error } = await supabase.from("locations").delete().eq("id", id);
  if (error) throw error;
}
