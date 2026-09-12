"use client";

import { CalendarClock, ChevronRight } from "lucide-react";
import Link from "next/link";
import { BookingWorkspaceShell } from "@/features/booking/components/booking-workspace-shell";
import { bookingPointBase } from "@/features/booking/lib/booking-prefs";
import { serviceTileIcon } from "@/lib/service-accent";

/**
 * Хаб настроек записи — правила **выбранной точки** (как Настройки компании в посещаемости).
 */
export function BookingSettingsHubView({ pointId }: { pointId: string }) {
  const base = bookingPointBase(pointId);

  return (
    <BookingWorkspaceShell pointId={pointId} title="Настройки">
      <div className="mx-auto max-w-2xl space-y-6">
        <div>
          <p className="text-[15px] font-bold text-ink">Настройки этой точки</p>
          <p className="mt-1 text-[13px] text-muted">
            Часы, окно записи и правила отмены — только для выбранной точки. У другой
            точки свои настройки.
          </p>
        </div>

        <ul className="overflow-hidden rounded-[16px] border border-line bg-surface">
          <li>
            <Link
              href={`${base}/settings/schedule`}
              className="flex items-center gap-3 px-3.5 py-3.5 transition hover:bg-svc-booking/40"
            >
              <span className={serviceTileIcon("booking")}>
                <CalendarClock className="h-5 w-5" strokeWidth={2} />
              </span>
              <span className="min-w-0 flex-1">
                <span className="block text-[15px] font-bold text-ink">Расписание</span>
                <span className="block text-[12px] text-muted">
                  Часы, выходные, горизонт, отмена, блокировки
                </span>
              </span>
              <ChevronRight className="h-5 w-5 text-muted" strokeWidth={2} />
            </Link>
          </li>
        </ul>
      </div>
    </BookingWorkspaceShell>
  );
}
