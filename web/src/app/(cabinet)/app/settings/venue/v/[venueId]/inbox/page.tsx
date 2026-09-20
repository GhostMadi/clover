import { VenueInboxView } from "@/features/venue/components/venue-inbox-view";

type Props = { params: Promise<{ venueId: string }> };

export default async function VenueInboxPage({ params }: Props) {
  const { venueId } = await params;
  return <VenueInboxView venueId={venueId} />;
}
