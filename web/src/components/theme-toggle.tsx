"use client";

import { Moon, Sun } from "lucide-react";
import { useEffect, useState } from "react";
import {
  readTheme,
  writeTheme,
  type WebThemeMode,
} from "@/features/settings/lib/prefs";

export function ThemeToggle() {
  const [theme, setTheme] = useState<WebThemeMode>("light");
  const [ready, setReady] = useState(false);

  useEffect(() => {
    setTheme(readTheme());
    setReady(true);
  }, []);

  const toggle = () => {
    const next: WebThemeMode = theme === "dark" ? "light" : "dark";
    setTheme(next);
    writeTheme(next);
  };

  return (
    <button
      type="button"
      onClick={toggle}
      aria-label={theme === "dark" ? "Светлая тема" : "Тёмная тема"}
      className="inline-flex h-10 w-10 items-center justify-center rounded-[12px] border border-line bg-surface text-ink transition hover:border-brand hover:text-brand"
    >
      {ready && theme === "dark" ? (
        <Sun className="h-[18px] w-[18px]" strokeWidth={2} />
      ) : (
        <Moon className="h-[18px] w-[18px]" strokeWidth={2} />
      )}
    </button>
  );
}
