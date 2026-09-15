import {
  mapHostBooking,
  mapMyBooking,
  type BookingStatus,
  type HostBookingItem,
  type MyBookingItem,
} from "@/features/booking/lib/booking-model";
import { createClient } from "@/lib/supabase/client";

export async function listHostBookings(params: {
  from: Date;
  to: Date;
  query?: string;
  limit?: number;
}): Promise<HostBookingItem[]> {
  const supabase = createClient();
  const { data, error } = await supabase.rpc("list_host_bookings_enriched", {
    p_from: params.from.toISOString(),
    p_to: params.to.toISOString(),
    p_query: params.query?.trim() || null,
    p_cursor: null,
    p_limit: params.limit ?? 100,
  });
  if (error) throw error;
  if (!Array.isArray(data)) return [];
  return data
    .filter((r): r is Record<string, unknown> => !!r && typeof r === "object")
    .map(mapHostBooking);
}

export async function listMyBookings(params: {
  from: Date;
  to: Date;
  limit?: number;
}): Promise<MyBookingItem[]> {
  const supabase = createClient();
  const { data, error } = await supabase.rpc("list_my_bookings_enriched", {
    p_from: params.from.toISOString(),
    p_to: params.to.toISOString(),
    p_cursor: null,
    p_limit: params.limit ?? 100,
  });
  if (error) throw error;
  if (!Array.isArray(data)) return [];
  return data
    .filter((r): r is Record<string, unknown> => !!r && typeof r === "object")
    .map(mapMyBooking);
}

/** Deep-link / notification open — роль client|host с бэка. */
export type BookingViewerResult =
  | { role: "client"; item: MyBookingItem }
  | { role: "host"; item: HostBookingItem };

export async function getBookingForViewer(
  bookingId: string,
): Promise<BookingViewerResult | null> {
  const id = bookingId.trim();
  if (!id) return null;
  const supabase = createClient();
  const { data, error } = await supabase.rpc("get_booking_enriched_for_viewer", {
    p_booking_id: id,
  });
  if (error) throw error;
  if (!data || typeof data !== "object") return null;
  const map = data as Record<string, unknown>;
  const role = String(map.role ?? "").trim();
  const raw = map.item;
  if (!raw || typeof raw !== "object") return null;
  const item = raw as Record<string, unknown>;
  if (role === "client") return { role: "client", item: mapMyBooking(item) };
  if (role === "host") return { role: "host", item: mapHostBooking(item) };
  return null;
}

export async function updateBookingStatus(
  bookingId: string,
  status: BookingStatus,
): Promise<void> {
  const supabase = createClient();
  const { error } = await supabase.rpc("update_booking_status", {
    p_booking_id: bookingId,
    p_status: status,
  });
  if (error) throw error;
}

export async function rescheduleBooking(params: {
  bookingId: string;
  staffId: string;
  startsAt: string;
  resetStatus?: BookingStatus;
}): Promise<void> {
  const supabase = createClient();
  const { error } = await supabase.rpc("reschedule_booking", {
    p_booking_id: params.bookingId,
    p_staff_id: params.staffId,
    p_starts_at: new Date(params.startsAt).toISOString(),
    p_reset_status: params.resetStatus ?? "confirmed",
  });
  if (error) throw error;
}

export async function revertBookingStatus(bookingId: string): Promise<BookingStatus> {
  const supabase = createClient();
  const { data, error } = await supabase.rpc("revert_booking_status", {
    p_booking_id: bookingId,
  });
  if (error) throw error;
  return String(data ?? "confirmed") as BookingStatus;
}
