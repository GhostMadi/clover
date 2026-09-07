/** Ярлык «Ресурсы» сбоку в кабинете (как ProfileResourcesShortcutStore). */

const KEY = "clover-web-resources-shortcut";

export const RESOURCES_SHORTCUT_EVENT = "clover:resources-shortcut";

function parseFlag(raw: string | null): boolean | null {
  if (raw === null) return null;
  return raw === "1" || raw === "true";
}

export function readResourcesShortcut(userId?: string | null): boolean {
  if (typeof window === "undefined") return false;
  try {
    if (userId) {
      const scoped = parseFlag(localStorage.getItem(`${KEY}:${userId}`));
      if (scoped !== null) return scoped;
    }
    return parseFlag(localStorage.getItem(KEY)) === true;
  } catch {
    return false;
  }
}

export function writeResourcesShortcut(
  userId: string | null | undefined,
  visible: boolean,
) {
  if (typeof window === "undefined") return;
  try {
    const v = visible ? "1" : "0";
    localStorage.setItem(KEY, v);
    if (userId) localStorage.setItem(`${KEY}:${userId}`, v);
    window.dispatchEvent(
      new CustomEvent(RESOURCES_SHORTCUT_EVENT, {
        detail: { userId: userId ?? undefined, visible },
      }),
    );
  } catch {
    /* private mode / blocked storage */
  }
}
