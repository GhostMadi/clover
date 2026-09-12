import { ScheduleSettingsView } from "@/features/booking/components/schedule-settings-view";

type Props = { params: Promise<{ pointId: string }> };

export default async function BookingPointScheduleSettingsPage({ params }: Props) {
  const { pointId } = await params;
  return <ScheduleSettingsView pointId={pointId} />;
}
