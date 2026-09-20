/**
 * In-flight coalesce + короткий memory-кэш (аналог `_networkInFlight` на мобилке).
 * Параллельные и близкие по времени вызовы с одним ключом делят один Promise / результат.
 */

type Entry<T> = {
  promise?: Promise<T>;
  value?: T;
  savedAt?: number;
};

const store = new Map<string, Entry<unknown>>();

/** Дефолт: 20с — хватает на switcher + вкладку при навигации. */
export const COALESCE_MEMORY_MS = 20_000;

export async function coalesceAsync<T>(
  key: string,
  run: () => Promise<T>,
  opts?: { memoryMs?: number },
): Promise<T> {
  const memoryMs = opts?.memoryMs ?? COALESCE_MEMORY_MS;
  const existing = store.get(key) as Entry<T> | undefined;

  if (existing?.promise) {
    return existing.promise;
  }

  if (
    existing &&
    existing.value !== undefined &&
    existing.savedAt != null &&
    Date.now() - existing.savedAt < memoryMs
  ) {
    return existing.value;
  }

  const promise = (async () => {
    try {
      const value = await run();
      store.set(key, { value, savedAt: Date.now() });
      return value;
    } catch (e) {
      store.delete(key);
      throw e;
    }
  })();

  store.set(key, { promise });
  return promise;
}

export function invalidateCoalesce(keyPrefix: string): void {
  for (const key of [...store.keys()]) {
    if (key === keyPrefix || key.startsWith(keyPrefix)) {
      store.delete(key);
    }
  }
}
