"use client";

import Link from "next/link";
import { BookingWorkspaceShell } from "@/features/booking/components/booking-workspace-shell";
import { bookingPointBase } from "@/features/booking/lib/booking-prefs";
import { BOOKING_GUIDE } from "@/features/booking/lib/booking-guide";

export function BookingGuideView({ pointId }: { pointId: string }) {
  const content = BOOKING_GUIDE;
  const back = bookingPointBase(pointId);

  return (
    <BookingWorkspaceShell pointId={pointId} title={content.pageTitle} backHref={back}>
      <div className="mx-auto max-w-2xl space-y-4">
        <div className="rounded-[16px] bg-svc-booking px-4 py-4">
          <p className="text-[15px] leading-snug text-ink">{content.lead}</p>
        </div>

        <ol className="space-y-3">
          {content.steps.map((step, index) => (
            <li
              key={step.title}
              className="flex gap-3 rounded-[16px] border border-line bg-surface px-3.5 py-3.5"
            >
              <span className="flex h-7 w-7 shrink-0 items-center justify-center rounded-[10px] bg-svc-booking text-[13px] font-bold text-svc-booking-ink">
                {index + 1}
              </span>
              <span className="min-w-0">
                <span className="block text-[15px] font-bold text-ink">{step.title}</span>
                <span className="mt-1 block text-[14px] leading-snug text-muted">{step.body}</span>
              </span>
            </li>
          ))}
        </ol>

        <Link
          href={back}
          className="block text-center text-[13px] font-semibold text-svc-booking-ink"
        >
          Назад к обзору
        </Link>
      </div>
    </BookingWorkspaceShell>
  );
}
