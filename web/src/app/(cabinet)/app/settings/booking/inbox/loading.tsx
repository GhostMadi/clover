import { BookingListShimmer } from "@/features/booking/components/booking-shimmers";
import { SettingsShell } from "@/features/settings/components/settings-shell";

export default function BookingInboxLoading() {
  return (
    <SettingsShell title="Мои записи" backHref="/app/settings/booking" service="booking">
      <div className="px-4 py-4">
        <BookingListShimmer rows={6} />
      </div>
    </SettingsShell>
  );
}
