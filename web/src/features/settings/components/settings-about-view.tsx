"use client";

import { SITE } from "@/lib/site";
import { SettingsShell } from "@/features/settings/components/settings-shell";

export function SettingsAboutView() {
  return (
    <SettingsShell title="О приложении">
      <div className="px-5 py-10">
        <p className="font-display text-3xl font-extrabold text-ink">{SITE.name}</p>
        <p className="mt-2 text-[15px] leading-relaxed text-muted">
          Веб-кабинет для авторов и бизнеса: публикации, карта, чат и профиль — в одном месте.
        </p>
        <dl className="mt-8 space-y-0 text-[14px]">
          <div className="flex items-center justify-between gap-3 border-b border-line py-3">
            <dt className="text-muted">Версия</dt>
            <dd className="font-semibold text-ink">{SITE.webVersion}</dd>
          </div>
          <div className="flex items-center justify-between gap-3 border-b border-line py-3">
            <dt className="text-muted">Сайт</dt>
            <dd className="font-semibold text-ink">{SITE.domain}</dd>
          </div>
          <div className="flex items-center justify-between gap-3 border-b border-line py-3">
            <dt className="text-muted">Поддержка</dt>
            <dd className="font-semibold text-ink">
              <a href={SITE.supportPath} className="text-brand underline underline-offset-2">
                {SITE.domain}
                {SITE.supportPath}
              </a>
            </dd>
          </div>
        </dl>
        <p className="mt-8 text-[13px] leading-relaxed text-muted">
          {SITE.freeNote}. Мобильное приложение и сайт работают с одними данными.
        </p>
      </div>
    </SettingsShell>
  );
}
