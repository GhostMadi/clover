/** Ярлык «Запись» сбоку в кабинете. */

const KEY = "clover-web-booking-shortcut";

export const BOOKING_SHORTCUT_EVENT = "clover:booking-shortcut";

export function readBookingShortcut(userId: string): boolean {
  if (typeof window === "undefined" || !userId) return false;
  try {
    const raw = localStorage.getItem(`${KEY}:${userId}`);
    if (raw === null) return false;
    return raw === "1" || raw === "true";
  } catch {
    return false;
  }
}

export function writeBookingShortcut(userId: string, visible: boolean) {
  if (typeof window === "undefined" || !userId) return;
  try {
    localStorage.setItem(`${KEY}:${userId}`, visible ? "1" : "0");
    window.dispatchEvent(
      new CustomEvent(BOOKING_SHORTCUT_EVENT, { detail: { userId, visible } }),
    );
  } catch {
    /* ignore */
  }
}
