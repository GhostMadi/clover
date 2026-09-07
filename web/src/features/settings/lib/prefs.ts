/** Локальные prefs кабинета (как ThemeCubit / язык в мобилке). */

import { lsGet, lsSet } from "@/lib/local-storage";

export type WebThemeMode = "light" | "dark";
export type WebLocaleCode = "ru" | "kk" | "en";

const THEME_KEY = "clover-web-theme";
const LOCALE_KEY = "clover-web-locale";

export const WEB_LOCALE_OPTIONS: { code: WebLocaleCode; label: string }[] = [
  { code: "ru", label: "Рус" },
  { code: "kk", label: "Қаз" },
  { code: "en", label: "Eng" },
];

export function readTheme(): WebThemeMode {
  return lsGet(THEME_KEY) === "dark" ? "dark" : "light";
}

export function writeTheme(mode: WebThemeMode) {
  lsSet(THEME_KEY, mode);
  if (typeof document !== "undefined") {
    document.documentElement.setAttribute("data-theme", mode);
  }
}

export function readLocale(): WebLocaleCode {
  const raw = lsGet(LOCALE_KEY);
  if (raw === "kk" || raw === "en" || raw === "ru") return raw;
  return "ru";
}

export function writeLocale(code: WebLocaleCode) {
  lsSet(LOCALE_KEY, code);
  if (typeof document !== "undefined") {
    document.documentElement.setAttribute("lang", code === "kk" ? "kk" : code);
  }
}
