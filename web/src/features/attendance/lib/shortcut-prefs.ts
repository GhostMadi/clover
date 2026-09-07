import { createBoolPref } from "@/lib/local-storage";

/** Ярлык «Посещаемость» сбоку в кабинете. */
const pref = createBoolPref({
  key: "clover-web-attendance-shortcut",
  event: "clover:attendance-shortcut",
});

export const ATTENDANCE_SHORTCUT_EVENT = pref.event;

export function readAttendanceShortcut(userId?: string | null): boolean {
  return pref.read(userId);
}

export function writeAttendanceShortcut(
  userId: string | null | undefined,
  visible: boolean,
) {
  pref.write(visible, userId);
}
