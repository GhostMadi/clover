import { BookingLegacyRedirect } from "@/features/booking/components/booking-legacy-redirect";

type Props = { params: Promise<{ id: string }> };

export default async function LegacyBookingServiceEditPage({ params }: Props) {
  const { id } = await params;
  return <BookingLegacyRedirect suffix={`/services/${id}`} />;
}
