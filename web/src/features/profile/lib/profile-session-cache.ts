"use client";

import type { Profile } from "@/features/profile/lib/profile-model";

type GuestCacheEntry = {
  profile: Profile;
  following: boolean;
  at: number;
};

const PREFIX = "clover_guest_profile_v1_";

function key(userId: string) {
  return `${PREFIX}${userId.trim()}`;
}

/** Session memory (sessionStorage) for guest profiles — paint-friendly revisit. */
export function readGuestProfileCache(
  userId: string,
): GuestCacheEntry | null {
  if (typeof window === "undefined") return null;
  const id = userId.trim();
  if (!id) return null;
  try {
    const raw = sessionStorage.getItem(key(id));
    if (!raw) return null;
    const parsed = JSON.parse(raw) as GuestCacheEntry;
    if (!parsed?.profile?.id) return null;
    return parsed;
  } catch {
    return null;
  }
}

export function writeGuestProfileCache(
  profile: Profile,
  following: boolean,
): void {
  if (typeof window === "undefined") return;
  const id = profile.id.trim();
  if (!id) return;
  try {
    const entry: GuestCacheEntry = {
      profile,
      following,
      at: Date.now(),
    };
    sessionStorage.setItem(key(id), JSON.stringify(entry));
  } catch {
    // quota / private mode
  }
}

export function clearGuestProfileCache(userId?: string): void {
  if (typeof window === "undefined") return;
  try {
    if (userId?.trim()) {
      sessionStorage.removeItem(key(userId));
      return;
    }
    const remove: string[] = [];
    for (let i = 0; i < sessionStorage.length; i++) {
      const k = sessionStorage.key(i);
      if (k?.startsWith(PREFIX)) remove.push(k);
    }
    for (const k of remove) sessionStorage.removeItem(k);
  } catch {
    // ignore
  }
}
