import type { BookingStatus } from "@/features/booking/lib/booking-model";
import { createClient } from "@/lib/supabase/client";

export type BookingCalendarHost = {
  hostId: string;
  hostDisplayName: string;
  hostUsername: string | null;
  staffId: string;
  staffDisplayName: string | null;
  isActive: boolean;
};

export type BookingCalendarItem = {
  id: string;
  hostId: string;
  hostDisplayName: string;
  hostUsername: string | null;
  clientId: string | null;
  clientName: string;
  clientUsername: string | null;
  serviceId: string | null;
  serviceTitle: string;
  serviceEmoji: string;
  durationMinutes: number;
  price: number;
  staffId: string | null;
  executorName: string | null;
  startsAt: string;
  status: BookingStatus;
  notes: string | null;
  createdAt: string | null;
};

function asStatus(raw: unknown): BookingStatus {
  const s = String(raw ?? "pending");
  switch (s) {
    case "pending":
    case "confirmed":
    case "client_arrived":
    case "in_progress":
    case "completed":
    case "cancelled":
    case "no_show":
      return s;
    default:
      return "pending";
  }
}

function mapHost(row: Record<string, unknown>): BookingCalendarHost {
  return {
    hostId: String(row.host_id ?? ""),
    hostDisplayName: String(row.host_display_name ?? ""),
    hostUsername: (row.host_username as string | null) ?? null,
    staffId: String(row.staff_id ?? ""),
    staffDisplayName: (row.staff_display_name as string | null) ?? null,
    isActive: row.is_active !== false,
  };
}

function mapItem(row: Record<string, unknown>): BookingCalendarItem {
  return {
    id: String(row.id ?? ""),
    hostId: String(row.host_id ?? ""),
    hostDisplayName: String(row.host_display_name ?? ""),
    hostUsername: (row.host_username as string | null) ?? null,
    clientId: (row.client_id as string | null) ?? null,
    clientName: String(row.client_name ?? ""),
    clientUsername: (row.client_username as string | null) ?? null,
    serviceId: (row.service_id as string | null) ?? null,
    serviceTitle: String(row.service_title ?? ""),
    serviceEmoji: String(row.service_emoji ?? "💈"),
    durationMinutes: Number(row.duration_minutes ?? 30) || 30,
    price: Number(row.price ?? 0) || 0,
    staffId: (row.staff_id as string | null) ?? null,
    executorName: (row.executor_name as string | null) ?? null,
    startsAt: String(row.starts_at ?? ""),
    status: asStatus(row.status),
    notes: (row.notes as string | null) ?? null,
    createdAt: (row.created_at as string | null) ?? null,
  };
}

export async function listCalendarHosts(): Promise<BookingCalendarHost[]> {
  const supabase = createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return [];
  const { data, error } = await supabase.rpc("list_my_staff_booking_hosts");
  if (error) throw error;
  if (!Array.isArray(data)) return [];
  return data
    .map((raw) => mapHost(raw as Record<string, unknown>))
    .filter((h) => h.hostId.length > 0);
}

export async function listCalendarBookings(opts: {
  from: Date;
  to: Date;
  hostId?: string | null;
  limit?: number;
}): Promise<BookingCalendarItem[]> {
  const supabase = createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return [];

  const params: Record<string, unknown> = {
    p_from: opts.from.toISOString(),
    p_to: opts.to.toISOString(),
    p_cursor: null,
    p_limit: opts.limit ?? 50,
  };
  const hostId = opts.hostId?.trim();
  if (hostId) params.p_host_id = hostId;

  const { data, error } = await supabase.rpc("list_my_staff_bookings_enriched", params);
  if (error) throw error;
  if (!Array.isArray(data)) return [];
  return data
    .map((raw) => mapItem(raw as Record<string, unknown>))
    .filter((b) => b.id.length > 0);
}
