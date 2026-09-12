/**
 * Prefs + кэш посещаемости (хаб компаний + табы SWR).
 * См. docs/business/website-service-cache.md
 */

import type { AnalyticsOverview } from "@/features/attendance/lib/attendance-analytics";
import type { PayrollPreview } from "@/features/attendance/lib/attendance-api";
import type {
  AttendanceAbsence,
  AttendanceDutyRoster,
  AttendanceFolder,
  AttendanceMembershipLite,
  AttendanceOvertime,
  AttendancePayrollRules,
  AttendancePunchRecord,
  AttendanceWorkplace,
} from "@/features/attendance/lib/attendance-model";
import { lsGet, lsSet } from "@/lib/local-storage";
import {
  readServiceCache,
  writeServiceCache,
} from "@/lib/service-sync-cache";

const LAST_KEY = "clover-web-attendance-last-workplace";
const HUB_BUCKET = "admin-hub";
const HUB_FULL_BUCKET = "admin-hub-full";
const HUB_VERSION = 1;
const TAB_VERSION = 1;
const HUB_TTL_MS = 7 * 24 * 60 * 60 * 1000;
const WORKPLACE_TTL_MS = 7 * 24 * 60 * 60 * 1000;
const DAY_TTL_MS = 24 * 60 * 60 * 1000;
const ANALYTICS_TTL_MS = 6 * 60 * 60 * 1000;

export type AttendanceHubCacheWorkplace = {
  id: string;
  name: string;
  folderId: string | null;
};

export type AttendanceHubCache = {
  workplaces: AttendanceHubCacheWorkplace[];
};

export type AttendanceHubFullCache = {
  folders: AttendanceFolder[];
  adminWorkplaces: AttendanceWorkplace[];
  isWorkerOnly: boolean;
  hasWorkerMembership: boolean;
};

type PunchCache = Omit<AttendancePunchRecord, "punchedAt"> & {
  punchedAt: string;
};

export type AttendanceTodayCache = {
  dayKey: string;
  workplace: AttendanceWorkplace;
  members: { id: string; name: string; username: string }[];
  punches: PunchCache[];
  absences: AttendanceAbsence[];
  overtime: AttendanceOvertime[];
};

export type AttendanceMembersCache = {
  members: Array<
    AttendanceMembershipLite & { displayName: string; username: string }
  >;
};

export type AttendanceDutyCache = {
  workplace: AttendanceWorkplace;
  roster: AttendanceDutyRoster;
  members: { id: string; name: string }[];
  labels: Record<string, { name: string; username: string }>;
  absences: AttendanceAbsence[];
  overtime: AttendanceOvertime[];
};

export type AttendanceAnalyticsCache = {
  periodStart: string;
  periodEnd: string;
  workplace: AttendanceWorkplace;
  overview: AnalyticsOverview;
};

export type AttendancePayrollCache = {
  periodStart: string;
  periodEnd: string;
  workplace: AttendanceWorkplace;
  rules: AttendancePayrollRules;
  preview: PayrollPreview;
};

export function attendanceLastWorkplaceKey(userId: string): string {
  return `${LAST_KEY}:${userId}`;
}

export function readLastAttendanceWorkplaceId(
  userId: string | null | undefined,
): string | null {
  if (!userId) return null;
  const raw = lsGet(attendanceLastWorkplaceKey(userId));
  const id = raw?.trim() ?? "";
  return id || null;
}

export function writeLastAttendanceWorkplaceId(
  userId: string | null | undefined,
  workplaceId: string,
): void {
  if (!userId || !workplaceId.trim()) return;
  lsSet(attendanceLastWorkplaceKey(userId), workplaceId.trim());
}

export function readAttendanceHubCache(
  userId: string | null | undefined,
): AttendanceHubCache | null {
  return readServiceCache<AttendanceHubCache>({
    service: "attendance",
    bucket: HUB_BUCKET,
    userId,
    version: HUB_VERSION,
    maxAgeMs: HUB_TTL_MS,
  });
}

export function writeAttendanceHubCache(
  userId: string | null | undefined,
  workplaces: AttendanceHubCacheWorkplace[],
): void {
  writeServiceCache({
    service: "attendance",
    bucket: HUB_BUCKET,
    userId,
    version: HUB_VERSION,
    data: { workplaces },
  });
}

export function readAttendanceHubFullCache(
  userId: string | null | undefined,
): AttendanceHubFullCache | null {
  return readServiceCache<AttendanceHubFullCache>({
    service: "attendance",
    bucket: HUB_FULL_BUCKET,
    userId,
    version: HUB_VERSION,
    maxAgeMs: HUB_TTL_MS,
  });
}

export function writeAttendanceHubFullCache(
  userId: string | null | undefined,
  data: AttendanceHubFullCache,
): void {
  writeServiceCache({
    service: "attendance",
    bucket: HUB_FULL_BUCKET,
    userId,
    version: HUB_VERSION,
    data,
  });
  writeAttendanceHubCache(
    userId,
    data.adminWorkplaces.map((w) => ({
      id: w.id,
      name: w.name,
      folderId: w.folderId,
    })),
  );
}

export function readAttendanceWorkplaceCache(
  userId: string | null | undefined,
  workplaceId: string,
): AttendanceWorkplace | null {
  return readServiceCache<AttendanceWorkplace>({
    service: "attendance",
    bucket: `workplace:${workplaceId}`,
    userId,
    version: TAB_VERSION,
    maxAgeMs: WORKPLACE_TTL_MS,
  });
}

export function writeAttendanceWorkplaceCache(
  userId: string | null | undefined,
  workplaceId: string,
  workplace: AttendanceWorkplace,
): void {
  writeServiceCache({
    service: "attendance",
    bucket: `workplace:${workplaceId}`,
    userId,
    version: TAB_VERSION,
    data: workplace,
  });
}

export function serializePunches(
  punches: AttendancePunchRecord[],
): PunchCache[] {
  return punches.map((p) => ({
    ...p,
    punchedAt: p.punchedAt.toISOString(),
  }));
}

export function revivePunches(punches: PunchCache[]): AttendancePunchRecord[] {
  return punches.map((p) => ({
    ...p,
    punchedAt: new Date(p.punchedAt),
  }));
}

export function readAttendanceTodayCache(
  userId: string | null | undefined,
  workplaceId: string,
  dayKeyStr: string,
): AttendanceTodayCache | null {
  const data = readServiceCache<AttendanceTodayCache>({
    service: "attendance",
    bucket: `today:${workplaceId}`,
    userId,
    version: TAB_VERSION,
    maxAgeMs: DAY_TTL_MS,
  });
  if (!data || data.dayKey !== dayKeyStr) return null;
  return data;
}

export function writeAttendanceTodayCache(
  userId: string | null | undefined,
  workplaceId: string,
  data: AttendanceTodayCache,
): void {
  writeServiceCache({
    service: "attendance",
    bucket: `today:${workplaceId}`,
    userId,
    version: TAB_VERSION,
    data,
  });
  writeAttendanceWorkplaceCache(userId, workplaceId, data.workplace);
}

export function readAttendanceMembersCache(
  userId: string | null | undefined,
  workplaceId: string,
): AttendanceMembersCache | null {
  return readServiceCache<AttendanceMembersCache>({
    service: "attendance",
    bucket: `members:${workplaceId}`,
    userId,
    version: TAB_VERSION,
    maxAgeMs: DAY_TTL_MS,
  });
}

export function writeAttendanceMembersCache(
  userId: string | null | undefined,
  workplaceId: string,
  members: AttendanceMembersCache["members"],
): void {
  writeServiceCache({
    service: "attendance",
    bucket: `members:${workplaceId}`,
    userId,
    version: TAB_VERSION,
    data: { members },
  });
}

export function readAttendanceDutyCache(
  userId: string | null | undefined,
  workplaceId: string,
): AttendanceDutyCache | null {
  return readServiceCache<AttendanceDutyCache>({
    service: "attendance",
    bucket: `duty:${workplaceId}`,
    userId,
    version: TAB_VERSION,
    maxAgeMs: DAY_TTL_MS,
  });
}

export function writeAttendanceDutyCache(
  userId: string | null | undefined,
  workplaceId: string,
  data: AttendanceDutyCache,
): void {
  writeServiceCache({
    service: "attendance",
    bucket: `duty:${workplaceId}`,
    userId,
    version: TAB_VERSION,
    data,
  });
  writeAttendanceWorkplaceCache(userId, workplaceId, data.workplace);
}

export function readAttendanceAnalyticsCache(
  userId: string | null | undefined,
  workplaceId: string,
  periodStart: string,
  periodEnd: string,
): AttendanceAnalyticsCache | null {
  const data = readServiceCache<AttendanceAnalyticsCache>({
    service: "attendance",
    bucket: `analytics:${workplaceId}:${periodStart}:${periodEnd}`,
    userId,
    version: TAB_VERSION,
    maxAgeMs: ANALYTICS_TTL_MS,
  });
  if (!data) return null;
  if (data.periodStart !== periodStart || data.periodEnd !== periodEnd) {
    return null;
  }
  return data;
}

export function writeAttendanceAnalyticsCache(
  userId: string | null | undefined,
  workplaceId: string,
  data: AttendanceAnalyticsCache,
): void {
  writeServiceCache({
    service: "attendance",
    bucket: `analytics:${workplaceId}:${data.periodStart}:${data.periodEnd}`,
    userId,
    version: TAB_VERSION,
    data,
  });
  writeAttendanceWorkplaceCache(userId, workplaceId, data.workplace);
}

export function readAttendancePayrollCache(
  userId: string | null | undefined,
  workplaceId: string,
  periodStart: string,
  periodEnd: string,
): AttendancePayrollCache | null {
  const data = readServiceCache<AttendancePayrollCache>({
    service: "attendance",
    bucket: `payroll:${workplaceId}:${periodStart}:${periodEnd}`,
    userId,
    version: TAB_VERSION,
    maxAgeMs: ANALYTICS_TTL_MS,
  });
  if (!data) return null;
  if (data.periodStart !== periodStart || data.periodEnd !== periodEnd) {
    return null;
  }
  return data;
}

export function writeAttendancePayrollCache(
  userId: string | null | undefined,
  workplaceId: string,
  data: AttendancePayrollCache,
): void {
  writeServiceCache({
    service: "attendance",
    bucket: `payroll:${workplaceId}:${data.periodStart}:${data.periodEnd}`,
    userId,
    version: TAB_VERSION,
    data,
  });
  writeAttendanceWorkplaceCache(userId, workplaceId, data.workplace);
}

/** last → иначе первая из списка; null если пусто. */
export function resolveAttendanceEntryWorkplaceId(
  userId: string | null | undefined,
  workplaceIds: string[],
): string | null {
  if (workplaceIds.length === 0) return null;
  const last = readLastAttendanceWorkplaceId(userId);
  if (last && workplaceIds.includes(last)) return last;
  return workplaceIds[0] ?? null;
}

/**
 * Заменить workplaceId в path, сохранив хвост
 * `/app/settings/attendance/w/OLD/members` → `…/w/NEW/members`
 */
export function swapAttendanceWorkplacePath(
  pathname: string,
  nextWorkplaceId: string,
): string {
  const re = /^(\/app\/settings\/attendance\/w\/)[^/]+(.*)$/;
  const m = pathname.match(re);
  if (!m) return `/app/settings/attendance/w/${nextWorkplaceId}`;
  return `${m[1]}${nextWorkplaceId}${m[2] || ""}`;
}
