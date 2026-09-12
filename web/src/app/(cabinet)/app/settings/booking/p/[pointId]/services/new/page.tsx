import { ServiceEditView } from "@/features/booking/components/service-edit-view";

type Props = { params: Promise<{ pointId: string }> };

export default async function BookingPointServiceNewPage({ params }: Props) {
  const { pointId } = await params;
  return <ServiceEditView pointId={pointId} mode="new" />;
}
