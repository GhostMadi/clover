import { BookingListShimmer } from "@/features/booking/components/booking-shimmers";
import { SettingsShell } from "@/features/settings/components/settings-shell";

export default function MyBookingsLoading() {
  return (
    <SettingsShell title="Мои бронирования" backHref="/app/settings/booking" service="booking">
      <div className="px-4 py-5">
        <BookingListShimmer rows={5} />
      </div>
    </SettingsShell>
  );
}
