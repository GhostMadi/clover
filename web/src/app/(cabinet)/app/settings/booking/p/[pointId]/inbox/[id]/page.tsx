import { HostBookingDetailView } from "@/features/booking/components/host-booking-detail-view";

type Props = { params: Promise<{ pointId: string; id: string }> };

export default async function BookingPointInboxDetailPage({ params }: Props) {
  const { pointId, id } = await params;
  return <HostBookingDetailView pointId={pointId} bookingId={id} />;
}
