import { VenueBookablesView } from "@/features/venue/components/venue-bookables-view";

type Props = { params: Promise<{ venueId: string }> };

export default async function VenueBookablesPage({ params }: Props) {
  const { venueId } = await params;
  return <VenueBookablesView venueId={venueId} />;
}
