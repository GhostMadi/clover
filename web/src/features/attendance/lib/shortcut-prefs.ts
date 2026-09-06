/** Ярлык «Посещаемость» сбоку в кабинете → admin-хаб. */

const KEY = "clover-web-attendance-shortcut";

export const ATTENDANCE_SHORTCUT_EVENT = "clover:attendance-shortcut";

export function readAttendanceShortcut(userId: string): boolean {
  if (typeof window === "undefined" || !userId) return false;
  try {
    const raw = localStorage.getItem(`${KEY}:${userId}`);
    if (raw === null) return false;
    return raw === "1" || raw === "true";
  } catch {
    return false;
  }
}

export function writeAttendanceShortcut(userId: string, visible: boolean) {
  if (typeof window === "undefined" || !userId) return;
  try {
    localStorage.setItem(`${KEY}:${userId}`, visible ? "1" : "0");
    window.dispatchEvent(
      new CustomEvent(ATTENDANCE_SHORTCUT_EVENT, {
        detail: { userId, visible },
      }),
    );
  } catch {
    /* ignore */
  }
}
