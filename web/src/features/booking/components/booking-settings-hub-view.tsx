"use client";

import { CalendarClock } from "lucide-react";
import { BookingWorkspaceShell } from "@/features/booking/components/booking-workspace-shell";
import { bookingPointBase } from "@/features/booking/lib/booking-prefs";
import { ServiceSection, ServiceTile } from "@/features/shared/components/service-page";

/**
 * Хаб настроек записи — правила **выбранной точки** (как Настройки компании в посещаемости).
 */
export function BookingSettingsHubView({ pointId }: { pointId: string }) {
  const base = bookingPointBase(pointId);

  return (
    <BookingWorkspaceShell
      pointId={pointId}
      title="Настройки"
      lead="Часы и правила только этой точки. У другой точки — свои."
    >
      <div className="mx-auto max-w-2xl">
        <ServiceSection label="Этой точки">
          <ServiceTile
            service="booking"
            href={`${base}/settings/schedule`}
            title="Расписание"
            subtitle="Часы работы, выходные, окно записи и отмена"
            icon={CalendarClock}
          />
        </ServiceSection>
      </div>
    </BookingWorkspaceShell>
  );
}
