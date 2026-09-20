import { VenueSessionsView } from "@/features/venue/components/venue-sessions-view";

type Props = { params: Promise<{ venueId: string }> };

export default async function VenueSessionsPage({ params }: Props) {
  const { venueId } = await params;
  return <VenueSessionsView venueId={venueId} />;
}
