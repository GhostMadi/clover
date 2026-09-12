import { HostInboxView } from "@/features/booking/components/host-inbox-view";

type Props = { params: Promise<{ pointId: string }> };

export default async function BookingPointInboxPage({ params }: Props) {
  const { pointId } = await params;
  return <HostInboxView pointId={pointId} />;
}
