import {
  mapService,
  type BookingService,
  type BookingCatalogItem,
} from "@/features/booking/lib/booking-model";
import { createClient } from "@/lib/supabase/client";

const STAFF_LINK =
  "staff_id, booking_staff(id, display_name, username, profile_id, is_active)";

const SERVICE_SELECT =
  "id, host_id, point_id, title, emoji_text, description, duration_minutes, buffer_after_minutes, price, max_participants, default_staff_id, is_active, sort_order, bonus_pay_percent, bonus_earn_amount";

const MY_SELECT = `${SERVICE_SELECT}, booking_service_staff(${STAFF_LINK})`;
const CATALOG_SELECT = MY_SELECT;

export type ServiceDraft = {
  title: string;
  emojiText: string;
  description?: string;
  durationMinutes: number;
  bufferAfterMinutes: number;
  price: number;
  maxParticipants: number;
  isActive: boolean;
  bonusPayPercent: number;
  bonusEarnAmount: number;
  staffIds: string[];
};

export async function listMyServices(pointId?: string): Promise<BookingService[]> {
  const supabase = createClient();
  const {
    data: { session },
  } = await supabase.auth.getSession();
  const user = session?.user ?? null;
  if (!user) return [];
  let q = supabase
    .from("booking_services")
    .select(MY_SELECT)
    .eq("host_id", user.id)
    .order("sort_order")
    .order("title");
  if (pointId) q = q.eq("point_id", pointId);
  const { data, error } = await q;
  if (error) throw error;
  return (data ?? []).map((row) => mapService(row as Record<string, unknown>));
}

export async function listServiceIdsForPoint(pointId: string): Promise<Set<string>> {
  const list = await listMyServices(pointId);
  return new Set(list.map((s) => s.id));
}

export async function listHostCatalog(hostId: string): Promise<BookingCatalogItem[]> {
  const id = hostId.trim();
  if (!id) return [];
  const supabase = createClient();
  const { data, error } = await supabase
    .from("booking_services")
    .select(CATALOG_SELECT)
    .eq("host_id", id)
    .eq("is_active", true)
    .order("sort_order")
    .order("title");
  if (error) throw error;
  return (data ?? []).map((row) => {
    const service = mapService(row as Record<string, unknown>);
    return { service, staff: service.staff };
  });
}

export async function getMyService(id: string): Promise<BookingService | null> {
  const supabase = createClient();
  const {
    data: { session },
  } = await supabase.auth.getSession();
  const user = session?.user ?? null;
  if (!user) return null;
  const { data, error } = await supabase
    .from("booking_services")
    .select(MY_SELECT)
    .eq("id", id)
    .eq("host_id", user.id)
    .maybeSingle();
  if (error) throw error;
  if (!data) return null;
  return mapService(data as Record<string, unknown>);
}

async function syncStaffLinks(serviceId: string, staffIds: string[]) {
  const supabase = createClient();
  await supabase.from("booking_service_staff").delete().eq("service_id", serviceId);
  const ids = staffIds.map((s) => s.trim()).filter(Boolean);
  if (!ids.length) return;
  const { error } = await supabase.from("booking_service_staff").insert(
    ids.map((staff_id) => ({ service_id: serviceId, staff_id })),
  );
  if (error) throw error;
}

function draftRow(draft: ServiceDraft, hostId: string, pointId?: string) {
  const desc = draft.description?.trim() ?? "";
  return {
    host_id: hostId,
    point_id: pointId ?? null,
    title: draft.title.trim(),
    emoji_text: draft.emojiText.trim() || "💈",
    duration_minutes: draft.durationMinutes,
    buffer_after_minutes: draft.bufferAfterMinutes,
    price: draft.price,
    max_participants: draft.maxParticipants,
    default_staff_id: draft.staffIds[0] ?? null,
    is_active: draft.isActive,
    bonus_pay_percent: draft.bonusPayPercent,
    bonus_earn_amount: draft.bonusEarnAmount,
    description: desc || null,
  } as Record<string, unknown>;
}

export async function createService(
  draft: ServiceDraft,
  pointId?: string,
): Promise<BookingService> {
  const supabase = createClient();
  const {
    data: { session },
  } = await supabase.auth.getSession();
  const user = session?.user ?? null;
  if (!user) throw new Error("Войдите в аккаунт");
  const { data, error } = await supabase
    .from("booking_services")
    .insert(draftRow(draft, user.id, pointId))
    .select(SERVICE_SELECT)
    .single();
  if (error) throw error;
  const service = mapService(data as Record<string, unknown>);
  await syncStaffLinks(service.id, draft.staffIds);
  return (await getMyService(service.id)) ?? service;
}

export async function updateService(id: string, draft: ServiceDraft): Promise<BookingService> {
  const supabase = createClient();
  const {
    data: { session },
  } = await supabase.auth.getSession();
  const user = session?.user ?? null;
  if (!user) throw new Error("Войдите в аккаунт");

  if (!draft.isActive) {
    const { error } = await supabase.rpc("deactivate_booking_service", {
      p_service_id: id,
    });
    if (error) throw error;
    const updated = await getMyService(id);
    if (!updated) throw new Error("Услуга не найдена");
    return updated;
  }

  const { error } = await supabase
    .from("booking_services")
    .update(draftRow(draft, user.id))
    .eq("id", id)
    .eq("host_id", user.id);
  if (error) throw error;
  await syncStaffLinks(id, draft.staffIds);
  const updated = await getMyService(id);
  if (!updated) throw new Error("Услуга не найдена");
  return updated;
}

export async function deactivateService(id: string): Promise<void> {
  const supabase = createClient();
  const { error } = await supabase.rpc("deactivate_booking_service", {
    p_service_id: id,
  });
  if (error) throw error;
}
