/** Admin-срез bootstrap посещаемости (веб). */

export type AttendanceFolder = {
  id: string;
  name: string;
};

export type AttendanceCustomPunch = {
  id: string;
  label: string;
  /** `HH:MM` для input[type=time], или null */
  scheduledTime: string | null;
  sortOrder: number;
};

export type AttendanceWorkplace = {
  id: string;
  name: string;
  folderId: string | null;
  isAdmin: boolean;
  latitude: number | null;
  longitude: number | null;
  geofenceRadiusM: number;
  clockInEnabled: boolean;
  clockOutEnabled: boolean;
  clockInScheduled: string | null;
  clockOutScheduled: string | null;
  dutyOnlyPunch: boolean;
  customPunches: AttendanceCustomPunch[];
  dutyRoster: AttendanceDutyRoster;
  payrollRules: AttendancePayrollRules;
  groupConversationId: string | null;
};

export type AttendanceDutyRoster = {
  workerIds: string[];
  /** ISO 1=Пн … 7=Вс */
  workingWeekdays: number[];
  startDate: string | null;
};

export type AttendancePayrollRules = {
  lateDeductsPay: boolean;
  overtimeAddsPay: boolean;
  absenceDeductsPay: boolean;
  partialDayDeductsPay: boolean;
  lateDeductPerMinute: number;
  overtimeBonusPerHour: number;
  absenceDeductPerDay: number;
  partialDayDeductPercent: number;
};

export const DEFAULT_PAYROLL_RULES: AttendancePayrollRules = {
  lateDeductsPay: false,
  overtimeAddsPay: false,
  absenceDeductsPay: true,
  partialDayDeductsPay: false,
  lateDeductPerMinute: 50,
  overtimeBonusPerHour: 1500,
  absenceDeductPerDay: 12000,
  partialDayDeductPercent: 50,
};

export type AttendanceAbsence = {
  id: string;
  workplaceId: string;
  profileId: string;
  kind: string;
  startDate: string;
  endDate: string;
  note: string | null;
};

export type AttendanceOvertime = {
  id: string;
  workplaceId: string;
  profileId: string;
  workDate: string;
  hours: number;
  status: string;
};

export type AttendanceMembershipLite = {
  id: string;
  workplaceId: string;
  profileId: string;
  status: string;
  baseSalaryTenge: number;
  workplaceName: string;
  shiftOpen: boolean;
  needsAck: boolean;
  ackVersion: number;
  configVersion: number;
};

export type AttendancePunchRecord = {
  id: string;
  workplaceId: string;
  profileId: string;
  punchKind: string;
  punchTypeId: string | null;
  label: string;
  punchedAt: Date;
  cancelled: boolean;
  cancelNote: string | null;
};

export type AttendanceAdminHub = {
  folders: AttendanceFolder[];
  adminWorkplaces: AttendanceWorkplace[];
  /** Есть membership active/pending без ownership — worker на сайте. */
  isWorkerOnly: boolean;
  /** Есть хотя бы одно своё membership (в т.ч. у admin). */
  hasWorkerMembership: boolean;
};

/** `13:00:00` / `9:00` → `HH:MM` */
export function parseTimeToInput(raw: unknown): string | null {
  if (raw == null) return null;
  const s = String(raw).trim();
  if (!s) return null;
  const m = s.match(/^(\d{1,2}):(\d{2})/);
  if (!m) return null;
  return `${m[1]!.padStart(2, "0")}:${m[2]}`;
}

/** `HH:MM` → `HH:MM:SS` для RPC */
export function timeToRpc(hhmm: string | null | undefined): string | null {
  if (!hhmm) return null;
  const s = hhmm.trim();
  if (!s) return null;
  if (/^\d{2}:\d{2}:\d{2}$/.test(s)) return s;
  if (/^\d{2}:\d{2}$/.test(s)) return `${s}:00`;
  return null;
}

export function mapFolder(raw: Record<string, unknown>): AttendanceFolder | null {
  const id = String(raw.id ?? "").trim();
  const name = String(raw.name ?? "").trim();
  if (!id || !name) return null;
  return { id, name };
}

export function mapCustomPunch(
  raw: Record<string, unknown>,
  index: number,
): AttendanceCustomPunch | null {
  const id = String(raw.id ?? "").trim();
  const label = String(raw.label ?? "").trim();
  if (!id || !label) return null;
  const sortOrder =
    typeof raw.sort_order === "number" ? raw.sort_order : index;
  return {
    id,
    label,
    scheduledTime: parseTimeToInput(raw.scheduled_time),
    sortOrder,
  };
}

export function mapDutyRoster(raw: unknown): AttendanceDutyRoster {
  if (!raw || typeof raw !== "object" || Array.isArray(raw)) {
    return { workerIds: [], workingWeekdays: [1, 2, 3, 4, 5], startDate: null };
  }
  const obj = raw as Record<string, unknown>;
  const ids = Array.isArray(obj.worker_ids)
    ? obj.worker_ids.map((e) => String(e).trim()).filter(Boolean)
    : [];
  const days = Array.isArray(obj.working_weekdays)
    ? obj.working_weekdays
        .map((e) => Number(e))
        .filter((n) => n >= 1 && n <= 7)
    : [1, 2, 3, 4, 5];
  const startRaw = obj.start_date == null ? "" : String(obj.start_date).trim();
  return {
    workerIds: ids,
    workingWeekdays: days.length > 0 ? days : [1, 2, 3, 4, 5],
    startDate: startRaw || null,
  };
}

export function dutyRosterToJson(r: AttendanceDutyRoster): Record<string, unknown> {
  return {
    worker_ids: r.workerIds,
    working_weekdays: [...r.workingWeekdays].sort((a, b) => a - b),
    ...(r.startDate ? { start_date: r.startDate } : {}),
  };
}

/** ISO weekday 1=Mon … 7=Sun */
export function isoWeekday(d: Date): number {
  const day = d.getDay();
  return day === 0 ? 7 : day;
}

export function dayKey(d: Date): Date {
  return new Date(d.getFullYear(), d.getMonth(), d.getDate());
}

export function formatDateKey(d: Date): string {
  const y = d.getFullYear();
  const m = String(d.getMonth() + 1).padStart(2, "0");
  const day = String(d.getDate()).padStart(2, "0");
  return `${y}-${m}-${day}`;
}

export function parseDateKey(s: string): Date {
  const [y, m, d] = s.split("-").map(Number);
  return new Date(y!, (m ?? 1) - 1, d ?? 1);
}

export function onDutyFor(roster: AttendanceDutyRoster, day: Date): string[] {
  if (roster.workerIds.length === 0) return [];
  const wd = isoWeekday(day);
  if (!roster.workingWeekdays.includes(wd)) return [];
  const target = dayKey(day);
  const anchor = roster.startDate
    ? dayKey(parseDateKey(roster.startDate))
    : new Date(target.getFullYear(), target.getMonth(), 1);
  let index = 0;
  const cursor = new Date(anchor);
  while (cursor < target) {
    if (roster.workingWeekdays.includes(isoWeekday(cursor))) index += 1;
    cursor.setDate(cursor.getDate() + 1);
  }
  return [roster.workerIds[index % roster.workerIds.length]!];
}

export function mapPayrollRules(raw: unknown): AttendancePayrollRules {
  if (!raw || typeof raw !== "object" || Array.isArray(raw)) {
    return { ...DEFAULT_PAYROLL_RULES };
  }
  const o = raw as Record<string, unknown>;
  return {
    lateDeductsPay: Boolean(o.late_deducts_pay ?? false),
    overtimeAddsPay: Boolean(o.overtime_adds_pay ?? false),
    absenceDeductsPay: o.absence_deducts_pay !== false,
    partialDayDeductsPay: Boolean(o.partial_day_deducts_pay ?? false),
    lateDeductPerMinute: Number(o.late_deduct_per_minute) || 50,
    overtimeBonusPerHour: Number(o.overtime_bonus_per_hour) || 1500,
    absenceDeductPerDay: Number(o.absence_deduct_per_day) || 12000,
    partialDayDeductPercent: Number(o.partial_day_deduct_percent) || 50,
  };
}

export function payrollRulesToJson(
  r: AttendancePayrollRules,
): Record<string, unknown> {
  return {
    late_deducts_pay: r.lateDeductsPay,
    overtime_adds_pay: r.overtimeAddsPay,
    absence_deducts_pay: r.absenceDeductsPay,
    partial_day_deducts_pay: r.partialDayDeductsPay,
    late_deduct_per_minute: r.lateDeductPerMinute,
    overtime_bonus_per_hour: r.overtimeBonusPerHour,
    absence_deduct_per_day: r.absenceDeductPerDay,
    partial_day_deduct_percent: r.partialDayDeductPercent,
  };
}

export function mapAbsence(raw: Record<string, unknown>): AttendanceAbsence | null {
  const id = String(raw.id ?? "").trim();
  const workplaceId = String(raw.workplace_id ?? "").trim();
  const profileId = String(raw.profile_id ?? "").trim();
  const kind = String(raw.kind ?? "").trim();
  const startDate = String(raw.start_date ?? "").trim();
  const endDate = String(raw.end_date ?? "").trim();
  if (!id || !workplaceId || !profileId || !kind || !startDate || !endDate) {
    return null;
  }
  return {
    id,
    workplaceId,
    profileId,
    kind,
    startDate,
    endDate,
    note: raw.note == null || raw.note === "" ? null : String(raw.note),
  };
}

export function mapOvertime(
  raw: Record<string, unknown>,
): AttendanceOvertime | null {
  const id = String(raw.id ?? "").trim();
  const workplaceId = String(raw.workplace_id ?? "").trim();
  const profileId = String(raw.profile_id ?? "").trim();
  const workDate = String(raw.work_date ?? "").trim();
  if (!id || !workplaceId || !profileId || !workDate) return null;
  return {
    id,
    workplaceId,
    profileId,
    workDate,
    hours: Number(raw.hours) || 0,
    status: String(raw.status ?? "").trim().toLowerCase(),
  };
}

export function mapWorkplace(
  raw: Record<string, unknown>,
  customPunches: AttendanceCustomPunch[] = [],
): AttendanceWorkplace | null {
  const id = String(raw.id ?? "").trim();
  const name = String(raw.name ?? "").trim();
  if (!id || !name) return null;
  const folderRaw = raw.folder_id;
  const folderId =
    folderRaw == null || folderRaw === ""
      ? null
      : String(folderRaw).trim() || null;
  const lat = raw.latitude;
  const lng = raw.longitude;
  const chat = raw.group_conversation_id;
  return {
    id,
    name,
    folderId,
    isAdmin: Boolean(raw.is_admin),
    latitude: typeof lat === "number" ? lat : lat != null ? Number(lat) : null,
    longitude: typeof lng === "number" ? lng : lng != null ? Number(lng) : null,
    geofenceRadiusM:
      typeof raw.geofence_radius_m === "number"
        ? raw.geofence_radius_m
        : Number(raw.geofence_radius_m) || 150,
    clockInEnabled: raw.clock_in_enabled !== false,
    clockOutEnabled: raw.clock_out_enabled !== false,
    clockInScheduled: parseTimeToInput(raw.clock_in_scheduled),
    clockOutScheduled: parseTimeToInput(raw.clock_out_scheduled),
    dutyOnlyPunch: Boolean(raw.duty_only_punch),
    customPunches,
    dutyRoster: mapDutyRoster(raw.duty_roster),
    payrollRules: mapPayrollRules(raw.payroll_rules),
    groupConversationId:
      chat == null || chat === "" ? null : String(chat).trim() || null,
  };
}

export function mapMembershipLite(
  raw: Record<string, unknown>,
): AttendanceMembershipLite | null {
  const id = String(raw.id ?? "").trim();
  const workplaceId = String(raw.workplace_id ?? "").trim();
  const profileId = String(raw.profile_id ?? "").trim();
  const status = String(raw.status ?? "").trim().toLowerCase();
  if (!id || !workplaceId || !profileId) return null;
  const salary = raw.base_salary_tenge;
  const ack =
    typeof raw.ack_version === "number"
      ? raw.ack_version
      : Number(raw.ack_version) || 0;
  const config =
    typeof raw.config_version === "number"
      ? raw.config_version
      : Number(raw.config_version) || 1;
  return {
    id,
    workplaceId,
    profileId,
    status,
    baseSalaryTenge:
      typeof salary === "number" ? salary : Number(salary) || 0,
    workplaceName: String(raw.workplace_name ?? "").trim() || "Компания",
    shiftOpen: Boolean(raw.shift_open),
    needsAck:
      Boolean(raw.needs_ack) ||
      (status === "active" && ack < config),
    ackVersion: ack,
    configVersion: config,
  };
}

export function mapPunchRecord(
  raw: Record<string, unknown>,
  typeLabels: Map<string, string> = new Map(),
): AttendancePunchRecord | null {
  const id = String(raw.id ?? "").trim();
  const workplaceId = String(raw.workplace_id ?? "").trim();
  const profileId = String(raw.profile_id ?? "").trim();
  const punchedAt = new Date(String(raw.punched_at ?? ""));
  if (!id || !workplaceId || !profileId || Number.isNaN(punchedAt.getTime())) {
    return null;
  }
  const kind = String(raw.punch_kind ?? "clock_in");
  const typeId =
    raw.punch_type_id == null || raw.punch_type_id === ""
      ? null
      : String(raw.punch_type_id);
  const label =
    kind === "clock_out"
      ? "Ушёл"
      : kind === "custom"
        ? typeLabels.get(typeId ?? "") || "Отметка"
        : "Пришёл";
  return {
    id,
    workplaceId,
    profileId,
    punchKind: kind,
    punchTypeId: typeId,
    label,
    punchedAt,
    cancelled: raw.cancelled_at != null,
    cancelNote:
      raw.cancel_note == null || raw.cancel_note === ""
        ? null
        : String(raw.cancel_note),
  };
}

export function isWorkerMembershipStatus(status: string): boolean {
  return status === "active" || status === "pending" || status === "accepted";
}

export function hasGeofenceCenter(w: AttendanceWorkplace): boolean {
  return (
    w.latitude != null &&
    w.longitude != null &&
    Number.isFinite(w.latitude) &&
    Number.isFinite(w.longitude)
  );
}

export function geofenceSubtitle(w: AttendanceWorkplace): string {
  if (!hasGeofenceCenter(w)) return "Точка не задана";
  return `Радиус ${w.geofenceRadiusM} м`;
}

export function punchTypesSubtitle(w: AttendanceWorkplace): string {
  const parts: string[] = [];
  if (w.clockInEnabled) {
    parts.push(
      w.clockInScheduled ? `Пришёл ${w.clockInScheduled}` : "Пришёл",
    );
  }
  if (w.clockOutEnabled) {
    parts.push(
      w.clockOutScheduled ? `Ушёл ${w.clockOutScheduled}` : "Ушёл",
    );
  }
  if (w.customPunches.length > 0) {
    parts.push(`${w.customPunches.length} свои`);
  }
  return parts.length === 0 ? "Не настроено" : parts.join(" · ");
}

export const ABSENCE_KIND_LABEL: Record<string, string> = {
  day_off: "Выходной",
  vacation: "Отпуск",
  sick: "Больничный",
};

export const WEEKDAY_SHORT: Record<number, string> = {
  1: "Пн",
  2: "Вт",
  3: "Ср",
  4: "Чт",
  5: "Пт",
  6: "Сб",
  7: "Вс",
};

export function formatMinutes(mins: number): string {
  const h = Math.floor(mins / 60);
  const m = mins % 60;
  if (h <= 0) return `${m}м`;
  if (m === 0) return `${h}ч`;
  return `${h}ч ${m}м`;
}

export function monthPeriodToToday(): { start: string; end: string; label: string } {
  const now = dayKey(new Date());
  const start = new Date(now.getFullYear(), now.getMonth(), 1);
  const months = [
    "Январь",
    "Февраль",
    "Март",
    "Апрель",
    "Май",
    "Июнь",
    "Июль",
    "Август",
    "Сентябрь",
    "Октябрь",
    "Ноябрь",
    "Декабрь",
  ];
  return {
    start: formatDateKey(start),
    end: formatDateKey(now),
    label: `${months[now.getMonth()]} ${now.getFullYear()}`,
  };
}
