"use client";

import { ChevronRight, MapPin, SlidersHorizontal } from "lucide-react";
import Link from "next/link";
import { useEffect, useState } from "react";
import { createClient } from "@/lib/supabase/client";
import { serviceTileIcon } from "@/lib/service-accent";
import { SettingsShell } from "@/features/settings/components/settings-shell";
import {
  readResourcesShortcut,
  writeResourcesShortcut,
} from "@/features/resources/lib/shortcut-prefs";

export function ResourcesHubView() {
  const [uid, setUid] = useState<string | null>(null);
  const [shortcut, setShortcut] = useState(false);

  useEffect(() => {
    setShortcut(readResourcesShortcut());
    void createClient()
      .auth.getSession()
      .then(({ data }) => {
        const id = data.session?.user.id ?? null;
        setUid(id);
        setShortcut(readResourcesShortcut(id));
      });
  }, []);

  return (
    <SettingsShell title="Ресурсы" service="resources">
      <div className="space-y-6 px-4 py-5">
        <section>
          <p className="mb-2 px-1 text-[12px] font-bold uppercase tracking-wide text-muted">
            Профиль
          </p>
          <div className="rounded-[16px] border border-line bg-surface px-3.5 py-3.5">
            <div className="flex items-start justify-between gap-3">
              <div className="min-w-0 flex-1">
                <p className="text-[15px] font-bold text-ink">Кнопка «Ресурсы» сбоку</p>
                <p className="mt-0.5 text-[12px] text-muted">
                  В боковом меню (десктоп) и справа у нижней навигации на профиле
                </p>
              </div>
              <button
                type="button"
                role="switch"
                aria-checked={shortcut}
                onClick={() => {
                  const next = !shortcut;
                  setShortcut(next);
                  writeResourcesShortcut(uid, next);
                }}
                className={`relative h-7 w-12 shrink-0 rounded-full transition ${
                  shortcut ? "bg-svc-resources-ink" : "bg-line"
                }`}
              >
                <span
                  className={`absolute top-0.5 h-6 w-6 rounded-full bg-surface shadow-elevate-sm transition ${
                    shortcut ? "left-[1.35rem]" : "left-0.5"
                  }`}
                />
              </button>
            </div>
          </div>
        </section>

        <section>
          <p className="mb-2 px-1 text-[12px] font-bold uppercase tracking-wide text-muted">
            Справочники
          </p>
          <ul className="overflow-hidden rounded-[16px] border border-line bg-surface">
            <li className="border-b border-line">
              <Link
                href="/app/settings/resources/locations"
                className="flex items-center gap-3 px-3.5 py-3.5 transition hover:bg-svc-resources/40"
              >
                <span className={serviceTileIcon("resources")}>
                  <MapPin className="h-5 w-5" strokeWidth={2} />
                </span>
                <span className="min-w-0 flex-1">
                  <span className="block text-[15px] font-bold text-ink">Местоположения</span>
                  <span className="block text-[12px] text-muted">
                    Адреса и точки на карте для постов
                  </span>
                </span>
                <ChevronRight className="h-5 w-5 text-muted" strokeWidth={2} />
              </Link>
            </li>
            <li>
              <Link
                href="/app/settings/resources/filters"
                className="flex items-center gap-3 px-3.5 py-3.5 transition hover:bg-svc-resources/40"
              >
                <span className={serviceTileIcon("resources")}>
                  <SlidersHorizontal className="h-5 w-5" strokeWidth={2} />
                </span>
                <span className="min-w-0 flex-1">
                  <span className="block text-[15px] font-bold text-ink">Фильтры</span>
                  <span className="block text-[12px] text-muted">
                    Категории витрины профиля
                  </span>
                </span>
                <ChevronRight className="h-5 w-5 text-muted" strokeWidth={2} />
              </Link>
            </li>
          </ul>
        </section>
      </div>
    </SettingsShell>
  );
}
