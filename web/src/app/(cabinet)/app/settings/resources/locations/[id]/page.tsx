import { LocationDetailView } from "@/features/resources/components/location-detail-view";

type Props = { params: Promise<{ id: string }> };

export default async function ResourcesLocationDetailPage({ params }: Props) {
  const { id } = await params;
  return <LocationDetailView locationId={id} />;
}
