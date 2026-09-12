import { ServicesListView } from "@/features/booking/components/services-list-view";

type Props = { params: Promise<{ pointId: string }> };

export default async function BookingPointServicesPage({ params }: Props) {
  const { pointId } = await params;
  return <ServicesListView pointId={pointId} />;
}
