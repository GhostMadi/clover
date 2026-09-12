import { BookingAnalyticsView } from "@/features/booking/components/booking-analytics-view";

type Props = { params: Promise<{ pointId: string }> };

export default async function BookingPointAnalyticsPage({ params }: Props) {
  const { pointId } = await params;
  return <BookingAnalyticsView pointId={pointId} />;
}
