/** Локальные prefs кабинета (как ThemeCubit / язык в мобилке). */

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
  if (typeof window === "undefined") return "light";
  try {
    return localStorage.getItem(THEME_KEY) === "dark" ? "dark" : "light";
  } catch {
    return "light";
  }
}

export function writeTheme(mode: WebThemeMode) {
  try {
    localStorage.setItem(THEME_KEY, mode);
  } catch {
    /* ignore */
  }
  document.documentElement.setAttribute("data-theme", mode);
}

export function readLocale(): WebLocaleCode {
  if (typeof window === "undefined") return "ru";
  try {
    const raw = localStorage.getItem(LOCALE_KEY);
    if (raw === "kk" || raw === "en" || raw === "ru") return raw;
  } catch {
    /* ignore */
  }
  return "ru";
}

export function writeLocale(code: WebLocaleCode) {
  try {
    localStorage.setItem(LOCALE_KEY, code);
  } catch {
    /* ignore */
  }
  document.documentElement.setAttribute("lang", code === "kk" ? "kk" : code);
}
