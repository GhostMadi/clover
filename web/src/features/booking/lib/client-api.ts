import {
  asNum,
  asStr,
  defaultScheduleSettings,
  type BookingAbsence,
  type BookingAvailability,
  type BookingBlockedSlot,
  type BookingScheduleSettings,
  type BookingSlot,
  type BookingSlotStatus,
  type HorizonKind,
} from "@/features/booking/lib/booking-model";
import { dateKeyLocal } from "@/features/booking/lib/booking-format";
import { createClient } from "@/lib/supabase/client";

function parseSlotStatus(raw: unknown): BookingSlotStatus {
  const s = String(raw ?? "").trim();
  if (s === "my_conflict" || s === "host_busy" || s === "selected") return s;
  return "available";
}

export async function getBookingAvailability(params: {
  hostId: string;
  serviceId: string;
  staffId: string;
  day: Date;
  excludeBookingId?: string;
}): Promise<BookingAvailability> {
  const supabase = createClient();
  const body: Record<string, unknown> = {
    p_host_id: params.hostId,
    p_service_id: params.serviceId,
    p_staff_id: params.staffId,
    p_day: dateKeyLocal(params.day),
  };
  if (params.excludeBookingId?.trim()) {
    body.p_exclude_booking_id = params.excludeBookingId.trim();
  }
  const { data, error } = await supabase.rpc("get_booking_availability", body);
  if (error) throw error;
  if (!data || typeof data !== "object") {
    return {
      dayUnavailableReason: null,
      slots: [],
      workStart: null,
      workEnd: null,
      slotStepMinutes: 30,
    };
  }
  const map = data as Record<string, unknown>;
  const slotsRaw = map.slots;
  const slots: BookingSlot[] = [];
  if (Array.isArray(slotsRaw)) {
    for (const item of slotsRaw) {
      if (!item || typeof item !== "object") continue;
      const s = item as Record<string, unknown>;
      const startsAt = asStr(s.starts_at);
      if (!startsAt) continue;
      slots.push({
        startsAt,
        status: parseSlotStatus(s.status),
        conflictLabel: asStr(s.conflict_label),
      });
    }
  }
  return {
    dayUnavailableReason: asStr(map.day_unavailable_reason),
    slots,
    workStart: asStr(map.work_start),
    workEnd: asStr(map.work_end),
    slotStepMinutes: asNum(map.slot_step_minutes, 30),
  };
}

export async function createBooking(params: {
  hostId: string;
  serviceId: string;
  staffId: string;
  startsAt: string;
  clientNotes?: string;
  participantsCount?: number;
  useBonuses?: boolean;
}): Promise<string> {
  const supabase = createClient();
  const { data, error } = await supabase.rpc("create_booking", {
    p_host_id: params.hostId,
    p_service_id: params.serviceId,
    p_staff_id: params.staffId,
    p_starts_at: new Date(params.startsAt).toISOString(),
    p_participants_count: params.participantsCount ?? 1,
    p_client_notes: params.clientNotes?.trim() || null,
    p_use_bonuses: params.useBonuses ?? true,
  });
  if (error) throw error;
  return String(data ?? "");
}

export async function getMyBonusBalanceAtHost(hostId: string): Promise<number> {
  const supabase = createClient();
  const { data, error } = await supabase.rpc("get_my_bonus_balance_at_host", {
    p_host_id: hostId,
  });
  if (error) throw error;
  return asNum(data, 0);
}

function mapAbsence(row: Record<string, unknown>): BookingAbsence {
  return {
    id: String(row.id ?? ""),
    staffId: String(row.staff_id ?? ""),
    startDate: String(row.start_date ?? "").slice(0, 10),
    endDate: String(row.end_date ?? "").slice(0, 10),
    note: asStr(row.note),
  };
}

function mapSettings(
  row: Record<string, unknown> | null,
  absences: BookingAbsence[],
): BookingScheduleSettings {
  const base = defaultScheduleSettings();
  if (!row) return { ...base, absences };
  const rest = Array.isArray(row.rest_weekdays)
    ? row.rest_weekdays.map((n) => asNum(n)).filter((n) => n >= 1 && n <= 7)
    : base.restWeekdays;
  const horizon = String(row.horizon_kind ?? "days_ahead") as HorizonKind;
  return {
    restWeekdays: rest,
    horizonKind: horizon === "until_date" ? "until_date" : "days_ahead",
    maxBookingDaysAhead: asNum(row.max_booking_days_ahead, 14),
    maxBookingUntilDate: asStr(row.max_booking_until_date)?.slice(0, 10) ?? null,
    workStart: String(row.default_work_start_time ?? base.workStart),
    workEnd: String(row.default_work_end_time ?? base.workEnd),
    clientCancelHoursBefore: asNum(row.client_cancel_hours_before, 0),
    autoCloseHoursAfterVisit: asNum(row.auto_close_hours_after_visit, 0),
    absences,
  };
}

export async function getScheduleSettings(hostId?: string): Promise<BookingScheduleSettings> {
  const supabase = createClient();
  const {
    data: { session },
  } = await supabase.auth.getSession();
  const user = session?.user ?? null;
  const id = (hostId ?? user?.id)?.trim();
  if (!id) return defaultScheduleSettings();

  const [{ data: settingsRow, error: sErr }, { data: absencesRes, error: aErr }] =
    await Promise.all([
      supabase.from("booking_schedule_settings").select().eq("host_id", id).maybeSingle(),
      supabase
        .from("booking_staff_absences")
        .select()
        .eq("host_id", id)
        .order("start_date"),
    ]);
  if (sErr) throw sErr;
  if (aErr) throw aErr;
  const absences = (absencesRes ?? []).map((r) => mapAbsence(r as Record<string, unknown>));
  return mapSettings((settingsRow as Record<string, unknown> | null) ?? null, absences);
}

export async function saveMyScheduleSettings(
  settings: BookingScheduleSettings,
): Promise<BookingScheduleSettings> {
  const supabase = createClient();
  const {
    data: { session },
  } = await supabase.auth.getSession();
  const user = session?.user ?? null;
  if (!user) throw new Error("Войдите в аккаунт");

  const start = settings.workStart.length === 5 ? `${settings.workStart}:00` : settings.workStart;
  const end = settings.workEnd.length === 5 ? `${settings.workEnd}:00` : settings.workEnd;

  const { error } = await supabase.from("booking_schedule_settings").upsert({
    host_id: user.id,
    rest_weekdays: settings.restWeekdays,
    horizon_kind: settings.horizonKind,
    max_booking_days_ahead: settings.maxBookingDaysAhead,
    max_booking_until_date:
      settings.horizonKind === "until_date" ? settings.maxBookingUntilDate : null,
    default_work_start_time: start,
    default_work_end_time: end,
    client_cancel_hours_before: settings.clientCancelHoursBefore,
    auto_close_hours_after_visit: settings.autoCloseHoursAfterVisit,
    auto_close_target: "no_show",
  });
  if (error) throw error;

  const { error: absErr } = await supabase.rpc("replace_booking_staff_absences", {
    p_absences: settings.absences.map((a) => ({
      staff_id: a.staffId,
      start_date: a.startDate,
      end_date: a.endDate,
      ...(a.note?.trim() ? { note: a.note.trim() } : {}),
    })),
  });
  if (absErr) throw absErr;

  return getScheduleSettings(user.id);
}

export async function listBlockedSlots(from: Date, to: Date): Promise<BookingBlockedSlot[]> {
  const supabase = createClient();
  const {
    data: { session },
  } = await supabase.auth.getSession();
  const user = session?.user ?? null;
  if (!user) return [];
  const { data, error } = await supabase
    .from("booking_blocked_slots")
    .select("id, staff_id, starts_at, ends_at, reason")
    .eq("host_id", user.id)
    .gte("starts_at", from.toISOString())
    .lte("starts_at", to.toISOString())
    .order("starts_at");
  if (error) throw error;
  return (data ?? []).map((row) => ({
    id: String(row.id),
    staffId: String(row.staff_id),
    startsAt: String(row.starts_at),
    endsAt: String(row.ends_at),
    reason: asStr(row.reason),
  }));
}

export async function createBlockedSlot(params: {
  staffId: string;
  startsAt: string;
  endsAt: string;
  reason?: string;
}): Promise<void> {
  const supabase = createClient();
  const {
    data: { session },
  } = await supabase.auth.getSession();
  const user = session?.user ?? null;
  if (!user) throw new Error("Войдите в аккаунт");
  const { error } = await supabase.from("booking_blocked_slots").insert({
    host_id: user.id,
    staff_id: params.staffId,
    starts_at: new Date(params.startsAt).toISOString(),
    ends_at: new Date(params.endsAt).toISOString(),
    ...(params.reason?.trim() ? { reason: params.reason.trim() } : {}),
  });
  if (error) throw error;
}

export async function deleteBlockedSlot(id: string): Promise<void> {
  const supabase = createClient();
  const { error } = await supabase.from("booking_blocked_slots").delete().eq("id", id);
  if (error) throw error;
}
