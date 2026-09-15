import { BookingDetailShimmer } from "@/features/booking/components/booking-shimmers";
import { BookingClientShell } from "@/features/booking/components/booking-workspace-shell";

export default function MyBookingDetailLoading() {
  return (
    <BookingClientShell title="Запись" backHref="/app/settings/booking/my">
      <BookingDetailShimmer />
    </BookingClientShell>
  );
}
