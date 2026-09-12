import { BookingLegacyRedirect } from "@/features/booking/components/booking-legacy-redirect";

type Props = { params: Promise<{ id: string }> };

export default async function LegacyBookingInboxDetailPage({ params }: Props) {
  const { id } = await params;
  return <BookingLegacyRedirect suffix={`/inbox/${id}`} />;
}
