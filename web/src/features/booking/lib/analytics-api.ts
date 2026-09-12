import { asNum, type BookingAnalytics } from "@/features/booking/lib/booking-model";
import { createClient } from "@/lib/supabase/client";

export async function getBookingAnalytics(params: {
  from: string;
  to: string;
  staffId?: string;
  pointId?: string;
}): Promise<BookingAnalytics> {
  const supabase = createClient();
  const body: Record<string, unknown> = {
    p_from: params.from,
    p_to: params.to,
  };
  if (params.staffId?.trim()) body.p_staff_id = params.staffId.trim();
  if (params.pointId?.trim()) body.p_point_id = params.pointId.trim();
  const { data, error } = await supabase.rpc("get_booking_analytics", body);
  if (error) throw error;
  const map = (data && typeof data === "object" ? data : {}) as Record<string, unknown>;
  const popularRaw = Array.isArray(map.popular_services) ? map.popular_services : [];
  const staffRaw = Array.isArray(map.top_staff) ? map.top_staff : [];
  return {
    totalBookings: asNum(map.total_bookings),
    pendingBookings: asNum(map.pending_bookings),
    confirmedBookings: asNum(map.confirmed_bookings),
    completedBookings: asNum(map.completed_bookings),
    cancelledBookings: asNum(map.cancelled_bookings),
    revenue: asNum(map.revenue),
    avgCheck: asNum(map.avg_check),
    popularServices: popularRaw
      .filter((r): r is Record<string, unknown> => !!r && typeof r === "object")
      .map((r) => ({
        serviceId: String(r.service_id ?? ""),
        title: String(r.title ?? ""),
        emojiText: String(r.emoji_text ?? "💈"),
        bookingCount: asNum(r.booking_count),
      })),
    topStaff: staffRaw
      .filter((r): r is Record<string, unknown> => !!r && typeof r === "object")
      .map((r) => ({
        staffId: String(r.staff_id ?? ""),
        displayName: String(r.display_name ?? ""),
        bookingCount: asNum(r.booking_count),
        revenue: asNum(r.revenue),
        completedCount: asNum(r.completed_count),
      })),
  };
}

export function emptyAnalytics(): BookingAnalytics {
  return {
    totalBookings: 0,
    pendingBookings: 0,
    confirmedBookings: 0,
    completedBookings: 0,
    cancelledBookings: 0,
    revenue: 0,
    avgCheck: 0,
    popularServices: [],
    topStaff: [],
  };
}

export function analyticsPeriodDefaults(now = new Date()): { from: string; to: string } {
  const to = now;
  const from = new Date(now.getFullYear(), now.getMonth(), 1);
  const fmt = (d: Date) =>
    `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}-${String(d.getDate()).padStart(2, "0")}`;
  return { from: fmt(from), to: fmt(to) };
}
