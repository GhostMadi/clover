import { ServiceEditView } from "@/features/booking/components/service-edit-view";

type Props = { params: Promise<{ pointId: string; id: string }> };

export default async function BookingPointServiceEditPage({ params }: Props) {
  const { pointId, id } = await params;
  return <ServiceEditView pointId={pointId} mode="edit" serviceId={id} />;
}
