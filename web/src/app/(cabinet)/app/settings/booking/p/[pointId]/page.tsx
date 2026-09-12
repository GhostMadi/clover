import { BookingHubView } from "@/features/booking/components/booking-hub-view";

type Props = { params: Promise<{ pointId: string }> };

export default async function BookingPointHubPage({ params }: Props) {
  const { pointId } = await params;
  return <BookingHubView pointId={pointId} />;
}
