import { createBoolPref } from "@/lib/local-storage";

/** Ярлык «Запись» сбоку в кабинете. */
const pref = createBoolPref({
  key: "clover-web-booking-shortcut",
  event: "clover:booking-shortcut",
});

export const BOOKING_SHORTCUT_EVENT = pref.event;

export function readBookingShortcut(userId?: string | null): boolean {
  return pref.read(userId);
}

export function writeBookingShortcut(
  userId: string | null | undefined,
  visible: boolean,
) {
  pref.write(visible, userId);
}
