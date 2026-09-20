import { VenueHubView } from "@/features/venue/components/venue-hub-view";

type Props = { params: Promise<{ venueId: string }> };

export default async function VenueHubPage({ params }: Props) {
  const { venueId } = await params;
  return <VenueHubView venueId={venueId} />;
}
