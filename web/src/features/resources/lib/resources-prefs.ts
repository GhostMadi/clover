/**
 * Prefs + кэш Ресурсов (SWR).
 * См. docs/business/website-service-cache.md
 */

import type { ManagedLocation } from "@/features/resources/lib/locations-api";
import type { ProfileFilterCategory } from "@/features/resources/lib/profile-filters-api";
import {
  readServiceCache,
  writeServiceCache,
  clearServiceCache,
} from "@/lib/service-sync-cache";

const TAB_VERSION = 1;
const LIST_TTL_MS = 7 * 24 * 60 * 60 * 1000;

export function readResourcesLocationsCache(
  userId: string | null | undefined,
): ManagedLocation[] | null {
  const data = readServiceCache<{ locations: ManagedLocation[] }>({
    service: "resources",
    bucket: "locations",
    userId,
    version: TAB_VERSION,
    maxAgeMs: LIST_TTL_MS,
  });
  return data?.locations ?? null;
}

export function writeResourcesLocationsCache(
  userId: string | null | undefined,
  locations: ManagedLocation[],
): void {
  writeServiceCache({
    service: "resources",
    bucket: "locations",
    userId,
    version: TAB_VERSION,
    data: { locations },
  });
}

export function readResourcesLocationCache(
  userId: string | null | undefined,
  locationId: string,
): ManagedLocation | null {
  return readServiceCache<ManagedLocation>({
    service: "resources",
    bucket: `location:${locationId}`,
    userId,
    version: TAB_VERSION,
    maxAgeMs: LIST_TTL_MS,
  });
}

export function writeResourcesLocationCache(
  userId: string | null | undefined,
  location: ManagedLocation,
): void {
  writeServiceCache({
    service: "resources",
    bucket: `location:${location.id}`,
    userId,
    version: TAB_VERSION,
    data: location,
  });
}

export function readResourcesProfileFiltersCache(
  userId: string | null | undefined,
): ProfileFilterCategory[] | null {
  const data = readServiceCache<{ categories: ProfileFilterCategory[] }>({
    service: "resources",
    bucket: "profile-filters",
    userId,
    version: TAB_VERSION,
    maxAgeMs: LIST_TTL_MS,
  });
  return data?.categories ?? null;
}

export function writeResourcesProfileFiltersCache(
  userId: string | null | undefined,
  categories: ProfileFilterCategory[],
): void {
  writeServiceCache({
    service: "resources",
    bucket: "profile-filters",
    userId,
    version: TAB_VERSION,
    data: { categories },
  });
}

/** Drop list + optional detail LS after mutation (coalesce invalidated separately). */
export function invalidateResourcesLocationsDiskCache(
  userId: string | null | undefined,
  locationId?: string | null,
): void {
  if (!userId) return;
  clearServiceCache({ service: "resources", bucket: "locations", userId });
  const id = locationId?.trim();
  if (id) {
    clearServiceCache({ service: "resources", bucket: `location:${id}`, userId });
  }
}

/** Clear all resources sync buckets + prefs for user (logout). */
export function clearResourcesSessionCaches(
  userId: string | null | undefined,
): void {
  if (!userId || typeof window === "undefined") return;
  try {
    const prefix = "clover-web-sync:resources:";
    const suffix = `:${userId}`;
    const keys: string[] = [];
    for (let i = 0; i < localStorage.length; i += 1) {
      const k = localStorage.key(i);
      if (k && k.startsWith(prefix) && k.endsWith(suffix)) keys.push(k);
    }
    for (const k of keys) localStorage.removeItem(k);
  } catch {
    /* ignore */
  }
}
