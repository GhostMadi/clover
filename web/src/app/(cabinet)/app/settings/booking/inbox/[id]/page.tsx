import { HostBookingDetailView } from "@/features/booking/components/host-booking-detail-view";

export default async function BookingInboxDetailPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;
  return <HostBookingDetailView bookingId={id} />;
}
