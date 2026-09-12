import { BookingGuideView } from "@/features/booking/components/booking-guide-view";

type Props = {
  params: Promise<{ pointId: string }>;
};

export default async function BookingGuidePage({ params }: Props) {
  const { pointId } = await params;
  return <BookingGuideView pointId={pointId} />;
}
