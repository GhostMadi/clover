/**
 * Prefs + кэш Ресурсов (SWR).
 * См. docs/business/website-service-cache.md
 */

import type { ManagedLocation } from "@/features/resources/lib/locations-api";
import type { ProfileFilterCategory } from "@/features/resources/lib/profile-filters-api";
import {
  readServiceCache,
  writeServiceCache,
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
