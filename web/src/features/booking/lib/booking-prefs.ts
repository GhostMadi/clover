/**
 * Prefs + кэш записи (точки + табы SWR).
 * См. docs/business/booking-points.md, docs/business/website-service-cache.md
 */

import type {
  BookingAnalytics,
  BookingBlockedSlot,
  BookingScheduleSettings,
  BookingService,
  BookingStaff,
  HostBookingItem,
} from "@/features/booking/lib/booking-model";
import { lsGet, lsSet } from "@/lib/local-storage";
import {
  readServiceCache,
  writeServiceCache,
} from "@/lib/service-sync-cache";

const LAST_KEY = "clover-web-booking-last-point";
const POINTS_BUCKET = "points";
const POINTS_VERSION = 1;
const POINTS_TTL_MS = 7 * 24 * 60 * 60 * 1000;

const TAB_VERSION = 1;
const SERVICES_TTL_MS = 7 * 24 * 60 * 60 * 1000;
const INBOX_TTL_MS = 24 * 60 * 60 * 1000;
const SCHEDULE_TTL_MS = 24 * 60 * 60 * 1000;
const ANALYTICS_TTL_MS = 6 * 60 * 60 * 1000;

export type BookingPointCacheItem = {
  id: string;
  name: string;
};

export type BookingServicesCache = {
  services: BookingService[];
  staff: BookingStaff[];
};

export type BookingInboxCache = {
  fromIso: string;
  toIso: string;
  items: HostBookingItem[];
};

export type BookingScheduleCache = {
  settings: BookingScheduleSettings;
  staff: BookingStaff[];
  blocks: BookingBlockedSlot[];
};

export function readLastBookingPointId(
  userId: string | null | undefined,
): string | null {
  if (!userId) return null;
  const raw = lsGet(`${LAST_KEY}:${userId}`);
  const id = raw?.trim() ?? "";
  return id || null;
}

export function writeLastBookingPointId(
  userId: string | null | undefined,
  pointId: string,
): void {
  if (!userId || !pointId.trim()) return;
  lsSet(`${LAST_KEY}:${userId}`, pointId.trim());
}

export function readBookingPointsCache(
  userId: string | null | undefined,
): BookingPointCacheItem[] | null {
  const data = readServiceCache<{ points: BookingPointCacheItem[] }>({
    service: "booking",
    bucket: POINTS_BUCKET,
    userId,
    version: POINTS_VERSION,
    maxAgeMs: POINTS_TTL_MS,
  });
  return data?.points ?? null;
}

export function writeBookingPointsCache(
  userId: string | null | undefined,
  points: BookingPointCacheItem[],
): void {
  writeServiceCache({
    service: "booking",
    bucket: POINTS_BUCKET,
    userId,
    version: POINTS_VERSION,
    data: { points },
  });
}

export function readBookingServicesCache(
  userId: string | null | undefined,
  pointId: string,
): BookingServicesCache | null {
  return readServiceCache<BookingServicesCache>({
    service: "booking",
    bucket: `services:${pointId}`,
    userId,
    version: TAB_VERSION,
    maxAgeMs: SERVICES_TTL_MS,
  });
}

export function writeBookingServicesCache(
  userId: string | null | undefined,
  pointId: string,
  data: BookingServicesCache,
): void {
  writeServiceCache({
    service: "booking",
    bucket: `services:${pointId}`,
    userId,
    version: TAB_VERSION,
    data,
  });
}

export function readBookingInboxCache(
  userId: string | null | undefined,
  pointId: string,
  range: { from: Date; to: Date },
): HostBookingItem[] | null {
  const data = readServiceCache<BookingInboxCache>({
    service: "booking",
    bucket: `inbox:${pointId}`,
    userId,
    version: TAB_VERSION,
    maxAgeMs: INBOX_TTL_MS,
  });
  if (!data) return null;
  if (
    data.fromIso !== range.from.toISOString() ||
    data.toIso !== range.to.toISOString()
  ) {
    // Окно сдвинулось — всё равно отдать stale, сеть обновит.
  }
  return data.items;
}

export function writeBookingInboxCache(
  userId: string | null | undefined,
  pointId: string,
  range: { from: Date; to: Date },
  items: HostBookingItem[],
): void {
  writeServiceCache({
    service: "booking",
    bucket: `inbox:${pointId}`,
    userId,
    version: TAB_VERSION,
    data: {
      fromIso: range.from.toISOString(),
      toIso: range.to.toISOString(),
      items,
    } satisfies BookingInboxCache,
  });
}

export function readBookingScheduleCache(
  userId: string | null | undefined,
  pointId: string,
): BookingScheduleCache | null {
  return readServiceCache<BookingScheduleCache>({
    service: "booking",
    bucket: `schedule:${pointId}`,
    userId,
    version: TAB_VERSION,
    maxAgeMs: SCHEDULE_TTL_MS,
  });
}

export function writeBookingScheduleCache(
  userId: string | null | undefined,
  pointId: string,
  data: BookingScheduleCache,
): void {
  writeServiceCache({
    service: "booking",
    bucket: `schedule:${pointId}`,
    userId,
    version: TAB_VERSION,
    data,
  });
}

export function readBookingAnalyticsCache(
  userId: string | null | undefined,
  from: string,
  to: string,
  pointId?: string,
): BookingAnalytics | null {
  const pid = pointId?.trim() || "host";
  return readServiceCache<BookingAnalytics>({
    service: "booking",
    bucket: `analytics:${pid}:${from}:${to}`,
    userId,
    version: TAB_VERSION,
    maxAgeMs: ANALYTICS_TTL_MS,
  });
}

export function writeBookingAnalyticsCache(
  userId: string | null | undefined,
  from: string,
  to: string,
  data: BookingAnalytics,
  pointId?: string,
): void {
  const pid = pointId?.trim() || "host";
  writeServiceCache({
    service: "booking",
    bucket: `analytics:${pid}:${from}:${to}`,
    userId,
    version: TAB_VERSION,
    data,
  });
}

export function bookingPointBase(pointId: string): string {
  return `/app/settings/booking/p/${pointId}`;
}

/** `/app/settings/booking/p/OLD/inbox` → `…/p/NEW/inbox` */
export function swapBookingPointPath(pathname: string, nextPointId: string): string {
  const re = /^(\/app\/settings\/booking\/p\/)[^/]+(.*)$/;
  const m = pathname.match(re);
  if (!m) return `${bookingPointBase(nextPointId)}/inbox`;
  return `${m[1]}${nextPointId}${m[2] || ""}`;
}
