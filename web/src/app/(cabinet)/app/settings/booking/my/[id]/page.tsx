import { MyBookingDetailView } from "@/features/booking/components/my-booking-detail-view";

type Props = { params: Promise<{ id: string }> };

export default async function MyBookingDetailPage({ params }: Props) {
  const { id } = await params;
  return <MyBookingDetailView bookingId={id} />;
}
