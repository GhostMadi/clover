import { BookingCatalogShimmer } from "@/features/booking/components/booking-shimmers";
import { SettingsShell } from "@/features/settings/components/settings-shell";

export default function BookHostLoading() {
  return (
    <SettingsShell title="Запись" backHref="/app" service="booking">
      <div className="px-4 py-5">
        <BookingCatalogShimmer />
      </div>
    </SettingsShell>
  );
}
