import { ServiceEditView } from "@/features/booking/components/service-edit-view";

export default async function BookingServiceEditPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;
  return <ServiceEditView mode="edit" serviceId={id} />;
}
