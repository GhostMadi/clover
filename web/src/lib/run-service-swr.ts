/**
 * Общий mount-хелпер SWR для сервисов хозяина.
 * Сначала кэш → paint, затем soft fetch → write.
 */

import { createClient } from "@/lib/supabase/client";

export async function getSessionUserId(): Promise<string | null> {
  const {
    data: { session },
  } = await createClient().auth.getSession();
  return session?.user.id ?? null;
}

export async function runServiceSwr<T>(opts: {
  read: (userId: string | null) => T | null;
  fetch: () => Promise<T>;
  write: (userId: string | null, data: T) => void;
  apply: (data: T) => void;
  setLoading: (loading: boolean) => void;
  setError?: (message: string | null) => void;
}): Promise<void> {
  const userId = await getSessionUserId();
  const cached = opts.read(userId);
  if (cached != null) {
    opts.apply(cached);
    opts.setLoading(false);
  } else {
    opts.setLoading(true);
  }
  opts.setError?.(null);
  try {
    const fresh = await opts.fetch();
    opts.apply(fresh);
    opts.write(userId, fresh);
  } catch (e: unknown) {
    if (cached == null) {
      opts.setError?.(e instanceof Error ? e.message : "Не удалось загрузить");
    }
  } finally {
    opts.setLoading(false);
  }
}
