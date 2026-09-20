import { VenueShowcaseView } from "@/features/venue/components/venue-showcase-view";

type Props = { params: Promise<{ venueId: string }> };

export default async function VenueShowcasePage({ params }: Props) {
  const { venueId } = await params;
  return <VenueShowcaseView venueId={venueId} />;
}
