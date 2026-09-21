import { Suspense } from "react";
import { BookingCalendarView } from "@/features/booking/components/booking-calendar-view";
import { BookingListShimmer } from "@/features/booking/components/booking-shimmers";
import { SettingsShell } from "@/features/settings/components/settings-shell";

export default function BookingCalendarPage() {
  return (
    <Suspense
      fallback={
        <SettingsShell title="Календарь" backHref="/app/settings" service="booking">
          <BookingListShimmer rows={4} />
        </SettingsShell>
      }
    >
      <BookingCalendarView />
    </Suspense>
  );
}
