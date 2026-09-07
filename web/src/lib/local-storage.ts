/**
 * Переиспользуемый скелет localStorage для веба.
 * Безопасно на SSR / private mode; опционально scope по userId.
 */

export function canUseLocalStorage(): boolean {
  return typeof window !== "undefined";
}

export function lsGet(key: string): string | null {
  if (!canUseLocalStorage()) return null;
  try {
    return localStorage.getItem(key);
  } catch {
    return null;
  }
}

export function lsSet(key: string, value: string): boolean {
  if (!canUseLocalStorage()) return false;
  try {
    localStorage.setItem(key, value);
    return true;
  } catch {
    return false;
  }
}

export function lsRemove(key: string): void {
  if (!canUseLocalStorage()) return;
  try {
    localStorage.removeItem(key);
  } catch {
    /* ignore */
  }
}

export function lsGetJson<T>(key: string): T | null {
  const raw = lsGet(key);
  if (raw == null) return null;
  try {
    return JSON.parse(raw) as T;
  } catch {
    return null;
  }
}

export function lsSetJson(key: string, value: unknown): boolean {
  try {
    return lsSet(key, JSON.stringify(value));
  } catch {
    return false;
  }
}

function parseBool(raw: string | null): boolean | null {
  if (raw === null) return null;
  if (raw === "1" || raw === "true") return true;
  if (raw === "0" || raw === "false") return false;
  return null;
}

/** Читает boolean; при scope сначала `key:userId`, потом общий `key`. */
export function lsGetBool(
  key: string,
  opts?: { userId?: string | null; fallback?: boolean },
): boolean {
  const fallback = opts?.fallback ?? false;
  const userId = opts?.userId;
  if (userId) {
    const scoped = parseBool(lsGet(`${key}:${userId}`));
    if (scoped !== null) return scoped;
  }
  const global = parseBool(lsGet(key));
  if (global !== null) return global;
  return fallback;
}

/** Пишет boolean в общий ключ и, если есть userId, в scoped. */
export function lsSetBool(
  key: string,
  value: boolean,
  opts?: { userId?: string | null },
): boolean {
  const raw = value ? "1" : "0";
  const ok = lsSet(key, raw);
  if (opts?.userId) lsSet(`${key}:${opts.userId}`, raw);
  return ok;
}

type BoolPrefDetail = { userId?: string; value: boolean };

/**
 * Фабрика boolean-pref + CustomEvent (тоглы drawer и т.п.).
 *
 * ```ts
 * const bookingShortcut = createBoolPref({
 *   key: "clover-web-booking-shortcut",
 *   event: "clover:booking-shortcut",
 * });
 * bookingShortcut.read(userId);
 * bookingShortcut.write(true, userId);
 * ```
 */
export function createBoolPref(opts: { key: string; event: string }) {
  const { key, event } = opts;

  function read(userId?: string | null): boolean {
    return lsGetBool(key, { userId, fallback: false });
  }

  function write(value: boolean, userId?: string | null): void {
    lsSetBool(key, value, { userId });
    if (!canUseLocalStorage()) return;
    try {
      window.dispatchEvent(
        new CustomEvent<BoolPrefDetail>(event, {
          detail: { userId: userId ?? undefined, value },
        }),
      );
    } catch {
      /* ignore */
    }
  }

  function subscribe(listener: (detail: BoolPrefDetail) => void): () => void {
    if (!canUseLocalStorage()) return () => {};
    const onCustom = (e: Event) => {
      listener((e as CustomEvent<BoolPrefDetail>).detail ?? { value: read() });
    };
    const onStorage = (e: StorageEvent) => {
      if (e.key === key || (e.key?.startsWith(`${key}:`) ?? false)) {
        listener({ value: read() });
      }
    };
    window.addEventListener(event, onCustom);
    window.addEventListener("storage", onStorage);
    return () => {
      window.removeEventListener(event, onCustom);
      window.removeEventListener("storage", onStorage);
    };
  }

  return { key, event, read, write, subscribe };
}
