"use client";

import { ArrowLeft } from "lucide-react";
import Link from "next/link";
import type { ReactNode } from "react";
import {
  SERVICE_ACCENT,
  type AppServiceKind,
} from "@/lib/service-accent";

type SettingsShellProps = {
  title: string;
  backHref?: string;
  children: ReactNode;
  /** Акцент сервиса (ресурсы / запись / …) — как SettingsScreenShell.service. */
  service?: AppServiceKind;
  trailing?: ReactNode;
};

/** Единый фон + шапка для экранов настроек / сервисов. */
export function SettingsShell({
  title,
  backHref = "/app/settings",
  children,
  service,
  trailing,
}: SettingsShellProps) {
  const accent = service ? SERVICE_ACCENT[service] : null;

  return (
    <div className="min-h-[calc(100dvh-3rem-4.25rem)] bg-bg md:min-h-dvh">
      <div className="mx-auto w-full max-w-[560px]">
        <header className="sticky top-0 z-10 flex h-12 items-center gap-2 border-b border-line bg-bg px-2">
          <Link
            href={backHref}
            className={`flex h-10 w-10 items-center justify-center rounded-full ${
              service === "resources"
                ? "text-svc-resources-ink hover:bg-svc-resources"
                : service === "booking"
                  ? "text-svc-booking-ink hover:bg-svc-booking"
                  : service === "attendance"
                    ? "text-svc-attendance-ink hover:bg-svc-attendance"
                    : service === "bonus"
                      ? "text-svc-bonus-ink hover:bg-svc-bonus"
                      : "text-ink hover:bg-surface-muted"
            }`}
            aria-label="Назад"
          >
            <ArrowLeft className="h-5 w-5" strokeWidth={2} />
          </Link>
          <h1
            className={`min-w-0 flex-1 truncate text-[16px] font-bold ${
              accent?.icon ?? "text-ink"
            }`}
          >
            {title}
          </h1>
          {trailing}
        </header>
        {children}
      </div>
    </div>
  );
}
