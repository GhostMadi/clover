/** Модели записи — те же ключи, что Flutter / RPC. */

export type BookingStatus =
  | "pending"
  | "confirmed"
  | "client_arrived"
  | "in_progress"
  | "completed"
  | "cancelled"
  | "no_show";

export type BookingStaff = {
  id: string;
  displayName: string;
  username: string | null;
  profileId: string | null;
  avatarUrl: string | null;
  isActive: boolean;
};

export type BookingService = {
  id: string;
  hostId: string;
  pointId: string | null;
  title: string;
  emojiText: string;
  description: string | null;
  durationMinutes: number;
  bufferAfterMinutes: number;
  price: number;
  maxParticipants: number;
  defaultStaffId: string | null;
  isActive: boolean;
  sortOrder: number;
  bonusPayPercent: number;
  bonusEarnAmount: number;
  staff: BookingStaff[];
  executorIds: string[];
};

export type BookingCatalogItem = {
  service: BookingService;
  staff: BookingStaff[];
};

export type BookingSlotStatus = "available" | "my_conflict" | "host_busy" | "selected";

export type BookingSlot = {
  startsAt: string;
  status: BookingSlotStatus;
  conflictLabel: string | null;
};

export type BookingAvailability = {
  dayUnavailableReason: string | null;
  slots: BookingSlot[];
  workStart: string | null;
  workEnd: string | null;
  slotStepMinutes: number;
};

export type HostBookingItem = {
  id: string;
  clientId: string | null;
  serviceId: string | null;
  staffId: string | null;
  clientName: string;
  serviceTitle: string;
  startsAt: string;
  status: BookingStatus;
  clientPhone: string | null;
  clientUsername: string | null;
  serviceEmoji: string;
  durationMinutes: number;
  price: number;
  executorName: string | null;
  notes: string | null;
  participantsCount: number;
  createdAt: string | null;
};

export type MyBookingItem = {
  id: string;
  hostId: string;
  hostDisplayName: string;
  hostUsername: string | null;
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
  clientCancelHoursBefore: number;
};

export type HorizonKind = "days_ahead" | "until_date";

export type BookingAbsence = {
  id: string;
  staffId: string;
  startDate: string;
  endDate: string;
  note: string | null;
};

export type BookingScheduleSettings = {
  restWeekdays: number[];
  horizonKind: HorizonKind;
  maxBookingDaysAhead: number;
  maxBookingUntilDate: string | null;
  workStart: string;
  workEnd: string;
  clientCancelHoursBefore: number;
  autoCloseHoursAfterVisit: number;
  absences: BookingAbsence[];
};

export type BookingBlockedSlot = {
  id: string;
  staffId: string;
  startsAt: string;
  endsAt: string;
  reason: string | null;
};

export type BookingAnalytics = {
  totalBookings: number;
  pendingBookings: number;
  confirmedBookings: number;
  completedBookings: number;
  cancelledBookings: number;
  revenue: number;
  avgCheck: number;
  popularServices: {
    serviceId: string;
    title: string;
    emojiText: string;
    bookingCount: number;
  }[];
  topStaff: {
    staffId: string;
    displayName: string;
    bookingCount: number;
    revenue: number;
    completedCount: number;
  }[];
};

export function defaultScheduleSettings(): BookingScheduleSettings {
  return {
    restWeekdays: [6, 7],
    horizonKind: "days_ahead",
    maxBookingDaysAhead: 14,
    maxBookingUntilDate: null,
    workStart: "10:00:00",
    workEnd: "20:00:00",
    clientCancelHoursBefore: 0,
    autoCloseHoursAfterVisit: 0,
    absences: [],
  };
}

export function asNum(v: unknown, fallback = 0): number {
  if (typeof v === "number" && Number.isFinite(v)) return v;
  if (typeof v === "string" && v.trim()) {
    const n = Number(v);
    if (Number.isFinite(n)) return n;
  }
  return fallback;
}

export function asStr(v: unknown): string | null {
  if (v == null) return null;
  const s = String(v).trim();
  return s || null;
}

export function parseStatus(raw: unknown): BookingStatus {
  const s = String(raw ?? "").trim();
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

export function mapStaff(row: Record<string, unknown>): BookingStaff {
  const profile = row.profiles as Record<string, unknown> | null | undefined;
  return {
    id: String(row.id ?? ""),
    displayName: String(row.display_name ?? ""),
    username: asStr(row.username),
    profileId: asStr(row.profile_id),
    avatarUrl: asStr(profile?.avatar_url ?? row.avatar_url),
    isActive: row.is_active !== false,
  };
}

export function mapLinkedStaff(raw: unknown): BookingStaff[] {
  if (!Array.isArray(raw)) return [];
  const out: BookingStaff[] = [];
  for (const item of raw) {
    if (!item || typeof item !== "object") continue;
    const link = item as Record<string, unknown>;
    const staffRaw = link.booking_staff;
    if (staffRaw && typeof staffRaw === "object") {
      out.push(mapStaff(staffRaw as Record<string, unknown>));
    }
  }
  return out.filter((s) => s.id && s.isActive !== false);
}

export function mapService(row: Record<string, unknown>): BookingService {
  const staff = mapLinkedStaff(row.booking_service_staff);
  return {
    id: String(row.id ?? ""),
    hostId: String(row.host_id ?? ""),
    pointId: asStr(row.point_id),
    title: String(row.title ?? ""),
    emojiText: String(row.emoji_text ?? "💈"),
    description: asStr(row.description),
    durationMinutes: asNum(row.duration_minutes, 30),
    bufferAfterMinutes: asNum(row.buffer_after_minutes, 0),
    price: asNum(row.price, 0),
    maxParticipants: asNum(row.max_participants, 1),
    defaultStaffId: asStr(row.default_staff_id),
    isActive: row.is_active !== false,
    sortOrder: asNum(row.sort_order, 0),
    bonusPayPercent: asNum(row.bonus_pay_percent, 0),
    bonusEarnAmount: asNum(row.bonus_earn_amount, 0),
    staff,
    executorIds: staff.map((s) => s.id),
  };
}

export function mapHostBooking(row: Record<string, unknown>): HostBookingItem {
  return {
    id: String(row.id ?? ""),
    clientId: asStr(row.client_id),
    serviceId: asStr(row.service_id),
    staffId: asStr(row.staff_id),
    clientName: String(row.client_name ?? ""),
    serviceTitle: String(row.service_title ?? ""),
    startsAt: String(row.starts_at ?? ""),
    status: parseStatus(row.status),
    clientPhone: asStr(row.client_phone),
    clientUsername: asStr(row.client_username),
    serviceEmoji: String(row.service_emoji ?? "💈"),
    durationMinutes: asNum(row.duration_minutes, 30),
    price: asNum(row.price, 0),
    executorName: asStr(row.executor_name),
    notes: asStr(row.notes),
    participantsCount: asNum(row.participants_count, 1),
    createdAt: asStr(row.created_at),
  };
}

export function mapMyBooking(row: Record<string, unknown>): MyBookingItem {
  return {
    id: String(row.id ?? ""),
    hostId: String(row.host_id ?? ""),
    hostDisplayName: String(row.host_display_name ?? ""),
    hostUsername: asStr(row.host_username),
    serviceId: asStr(row.service_id),
    serviceTitle: String(row.service_title ?? ""),
    serviceEmoji: String(row.service_emoji ?? "💈"),
    durationMinutes: asNum(row.duration_minutes, 30),
    price: asNum(row.price, 0),
    staffId: asStr(row.staff_id),
    executorName: asStr(row.executor_name),
    startsAt: String(row.starts_at ?? ""),
    status: parseStatus(row.status),
    notes: asStr(row.notes),
    createdAt: asStr(row.created_at),
    clientCancelHoursBefore: asNum(row.client_cancel_hours_before, 0),
  };
}
