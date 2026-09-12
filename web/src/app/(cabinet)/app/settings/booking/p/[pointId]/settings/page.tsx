import { BookingSettingsHubView } from "@/features/booking/components/booking-settings-hub-view";

type Props = { params: Promise<{ pointId: string }> };

export default async function BookingPointSettingsPage({ params }: Props) {
  const { pointId } = await params;
  return <BookingSettingsHubView pointId={pointId} />;
}
