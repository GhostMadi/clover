/**
 * Общий envelope кэша синхронизации сервисов хозяина (веб).
 * См. docs/business/website-service-cache.md
 */

import {
  canUseLocalStorage,
  lsGetJson,
  lsRemove,
  lsSetJson,
} from "@/lib/local-storage";
import type { AppServiceKind } from "@/lib/service-accent";

export type ServiceSyncEnvelope<T> = {
  v: number;
  savedAt: string;
  data: T;
};

const EVENT = "clover:service-sync-cache";

export function serviceCacheKey(
  service: AppServiceKind,
  bucket: string,
  userId: string,
): string {
  return `clover-web-sync:${service}:${bucket}:${userId}`;
}

export function readServiceCache<T>(opts: {
  service: AppServiceKind;
  bucket: string;
  userId: string | null | undefined;
  version: number;
  maxAgeMs: number;
}): T | null {
  if (!opts.userId) return null;
  const key = serviceCacheKey(opts.service, opts.bucket, opts.userId);
  const raw = lsGetJson<ServiceSyncEnvelope<T>>(key);
  if (!raw || raw.v !== opts.version || raw.data == null || !raw.savedAt) {
    return null;
  }
  const saved = Date.parse(raw.savedAt);
  if (!Number.isFinite(saved) || Date.now() - saved > opts.maxAgeMs) {
    lsRemove(key);
    return null;
  }
  return raw.data;
}

export function writeServiceCache<T>(opts: {
  service: AppServiceKind;
  bucket: string;
  userId: string | null | undefined;
  version: number;
  data: T;
}): void {
  if (!opts.userId) return;
  const key = serviceCacheKey(opts.service, opts.bucket, opts.userId);
  const ok = lsSetJson(key, {
    v: opts.version,
    savedAt: new Date().toISOString(),
    data: opts.data,
  } satisfies ServiceSyncEnvelope<T>);
  if (!ok || !canUseLocalStorage()) return;
  try {
    window.dispatchEvent(
      new CustomEvent(EVENT, {
        detail: { service: opts.service, bucket: opts.bucket, userId: opts.userId },
      }),
    );
  } catch {
    /* ignore */
  }
}

export function clearServiceCache(opts: {
  service: AppServiceKind;
  bucket: string;
  userId: string | null | undefined;
}): void {
  if (!opts.userId) return;
  lsRemove(serviceCacheKey(opts.service, opts.bucket, opts.userId));
}

export function subscribeServiceCache(
  listener: (detail: {
    service?: AppServiceKind;
    bucket?: string;
    userId?: string;
  }) => void,
): () => void {
  if (!canUseLocalStorage()) return () => {};
  const onCustom = (e: Event) => {
    listener((e as CustomEvent).detail ?? {});
  };
  window.addEventListener(EVENT, onCustom);
  return () => window.removeEventListener(EVENT, onCustom);
}
