"use client";

import Link from "next/link";
import { SettingsShell } from "@/features/settings/components/settings-shell";
import type { ServicesGuideContent } from "@/features/settings/lib/services-guide";

type Props = {
  content: ServicesGuideContent;
};

const HUB_HREF = {
  booking: "/app/settings/booking",
  attendance: "/app/settings/attendance",
  resources: "/app/settings/resources",
} as const;

const HUB_LABEL = {
  booking: "Открыть запись",
  attendance: "Открыть посещаемость",
  resources: "Открыть ресурсы",
} as const;

export function ServicesGuideTopicView({ content }: Props) {
  return (
    <SettingsShell title={content.pageTitle} backHref="/app/settings/guide">
      <div
        className={`mb-4 rounded-[16px] p-4 ${
          content.service === "booking"
            ? "bg-svc-booking"
            : content.service === "attendance"
              ? "bg-svc-attendance"
              : "bg-svc-resources"
        }`}
      >
        <p className="text-[15px] leading-snug text-ink">{content.lead}</p>
      </div>
      <ol className="space-y-4">
        {content.steps.map((step, i) => (
          <li key={step.title}>
            <p className="text-[16px] font-bold text-ink">
              {i + 1}. {step.title}
            </p>
            <p className="mt-1 text-[14px] leading-snug text-muted">{step.body}</p>
          </li>
        ))}
      </ol>
      <Link
        href={HUB_HREF[content.service]}
        className="mt-6 flex h-12 items-center justify-center rounded-[14px] bg-brand text-[15px] font-bold text-on-brand"
      >
        {HUB_LABEL[content.service]}
      </Link>
    </SettingsShell>
  );
}
