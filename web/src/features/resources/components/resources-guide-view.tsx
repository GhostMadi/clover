"use client";

import Link from "next/link";
import { AppButtonLink } from "@/components/shared/app-button";
import { SettingsShell } from "@/features/settings/components/settings-shell";
import type { ResourcesGuideContent } from "@/features/resources/lib/resources-guide";

type Props = {
  content: ResourcesGuideContent;
};

export function ResourcesGuideView({ content }: Props) {
  return (
    <SettingsShell title={content.pageTitle} service="resources" backHref="/app/settings/resources">
      <div className="space-y-4 px-4 py-5">
        <div className="rounded-[16px] bg-svc-resources px-4 py-4">
          <p className="text-[15px] leading-snug text-ink">{content.lead}</p>
        </div>

        <ol className="space-y-3">
          {content.steps.map((step, index) => (
            <li
              key={step.title}
              className="flex gap-3 rounded-[16px] border border-line bg-surface px-3.5 py-3.5"
            >
              <span className="flex h-7 w-7 shrink-0 items-center justify-center rounded-[10px] bg-svc-resources text-[13px] font-bold text-svc-resources-ink">
                {index + 1}
              </span>
              <span className="min-w-0">
                <span className="block text-[15px] font-bold text-ink">{step.title}</span>
                <span className="mt-1 block text-[14px] leading-snug text-muted">{step.body}</span>
              </span>
            </li>
          ))}
        </ol>

        {content.ctaLabel && content.ctaHref ? (
          <AppButtonLink href={content.ctaHref} service="resources" size="row" className="w-full">
            {content.ctaLabel}
          </AppButtonLink>
        ) : (
          <Link
            href="/app/settings/resources"
            className="block text-center text-[13px] font-semibold text-svc-resources-ink"
          >
            Назад к ресурсам
          </Link>
        )}
      </div>
    </SettingsShell>
  );
}
