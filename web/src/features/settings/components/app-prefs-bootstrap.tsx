"use client";

import { useEffect } from "react";
import { readLocale, readTheme, writeLocale, writeTheme } from "@/features/settings/lib/prefs";

/** Применяет тему и lang с localStorage (после гидрации). */
export function AppPrefsBootstrap() {
  useEffect(() => {
    writeTheme(readTheme());
    writeLocale(readLocale());
  }, []);
  return null;
}
