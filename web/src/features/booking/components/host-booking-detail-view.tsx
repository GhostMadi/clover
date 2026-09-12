"use client";

import { BookingWorkspaceShell } from "@/features/booking/components/booking-workspace-shell";
import { HostBookingDetailPanel } from "@/features/booking/components/host-booking-detail-panel";
import { bookingPointBase } from "@/features/booking/lib/booking-prefs";

export function HostBookingDetailView({
  pointId,
  bookingId,
}: {
  pointId: string;
  bookingId: string;
}) {
  return (
    <BookingWorkspaceShell
      pointId={pointId}
      title="Запись"
      backHref={`${bookingPointBase(pointId)}/inbox`}
    >
      <HostBookingDetailPanel bookingId={bookingId} />
    </BookingWorkspaceShell>
  );
}
