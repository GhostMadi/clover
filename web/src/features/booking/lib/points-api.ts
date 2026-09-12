import { createClient } from "@/lib/supabase/client";
import {
  writeBookingPointsCache,
  type BookingPointCacheItem,
} from "@/features/booking/lib/booking-prefs";

export type BookingPoint = {
  id: string;
  hostId: string;
  name: string;
  createdAt: string;
};

function mapPoint(row: Record<string, unknown>): BookingPoint {
  return {
    id: String(row.id),
    hostId: String(row.host_id),
    name: String(row.name ?? "").trim() || "Точка",
    createdAt: String(row.created_at ?? ""),
  };
}

export async function ensureDefaultBookingPoint(): Promise<string> {
  const supabase = createClient();
  const { data, error } = await supabase.rpc("booking_ensure_default_point");
  if (error) throw error;
  return String(data);
}

export async function listBookingPoints(): Promise<BookingPoint[]> {
  const supabase = createClient();
  const {
    data: { session },
  } = await supabase.auth.getSession();
  const user = session?.user ?? null;
  if (!user) return [];

  const { data, error } = await supabase
    .from("booking_points")
    .select("id, host_id, name, created_at")
    .eq("host_id", user.id)
    .is("archived_at", null)
    .order("created_at", { ascending: true });
  if (error) throw error;

  const points = (data ?? []).map((r) => mapPoint(r as Record<string, unknown>));
  if (points.length === 0) {
    const id = await ensureDefaultBookingPoint();
    const again = await supabase
      .from("booking_points")
      .select("id, host_id, name, created_at")
      .eq("id", id)
      .maybeSingle();
    if (again.data) {
      const one = mapPoint(again.data as Record<string, unknown>);
      writeBookingPointsCache(user.id, [{ id: one.id, name: one.name }]);
      return [one];
    }
  }

  writeBookingPointsCache(
    user.id,
    points.map((p) => ({ id: p.id, name: p.name }) satisfies BookingPointCacheItem),
  );
  return points;
}

export async function createBookingPoint(name: string): Promise<BookingPoint> {
  const trimmed = name.trim();
  if (!trimmed) throw new Error("Укажите название");
  const supabase = createClient();
  const {
    data: { session },
  } = await supabase.auth.getSession();
  const user = session?.user ?? null;
  if (!user) throw new Error("Войдите в аккаунт");

  const { data, error } = await supabase
    .from("booking_points")
    .insert({ host_id: user.id, name: trimmed })
    .select("id, host_id, name, created_at")
    .single();
  if (error) throw error;
  await listBookingPoints();
  return mapPoint(data as Record<string, unknown>);
}

export async function renameBookingPoint(params: {
  pointId: string;
  name: string;
}): Promise<void> {
  const trimmed = params.name.trim();
  if (!trimmed) throw new Error("Укажите название");
  const supabase = createClient();
  const { error } = await supabase
    .from("booking_points")
    .update({ name: trimmed })
    .eq("id", params.pointId);
  if (error) throw error;
}
