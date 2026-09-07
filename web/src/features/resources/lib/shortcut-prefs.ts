import { createBoolPref } from "@/lib/local-storage";

/** Ярлык «Ресурсы» сбоку в кабинете. */
const pref = createBoolPref({
  key: "clover-web-resources-shortcut",
  event: "clover:resources-shortcut",
});

export const RESOURCES_SHORTCUT_EVENT = pref.event;

export function readResourcesShortcut(userId?: string | null): boolean {
  return pref.read(userId);
}

export function writeResourcesShortcut(
  userId: string | null | undefined,
  visible: boolean,
) {
  pref.write(visible, userId);
}
