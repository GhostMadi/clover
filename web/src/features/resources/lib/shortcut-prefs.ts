/** Ярлык «Ресурсы» сбоку в кабинете (как ProfileResourcesShortcutStore). */

const KEY = "clover-web-resources-shortcut";

export const RESOURCES_SHORTCUT_EVENT = "clover:resources-shortcut";

export function readResourcesShortcut(userId: string): boolean {
  if (typeof window === "undefined" || !userId) return false;
  try {
    const raw = localStorage.getItem(`${KEY}:${userId}`);
    if (raw === null) return false;
    return raw === "1" || raw === "true";
  } catch {
    return false;
  }
}

export function writeResourcesShortcut(userId: string, visible: boolean) {
  if (typeof window === "undefined" || !userId) return;
  try {
    localStorage.setItem(`${KEY}:${userId}`, visible ? "1" : "0");
    window.dispatchEvent(
      new CustomEvent(RESOURCES_SHORTCUT_EVENT, { detail: { userId, visible } }),
    );
  } catch {
    /* ignore */
  }
}
