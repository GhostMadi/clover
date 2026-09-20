import { VenuePlanEditorPage } from "@/features/venue/components/venue-plan-editor-page";

type Props = { params: Promise<{ venueId: string }> };

export default async function VenuePlanPage({ params }: Props) {
  const { venueId } = await params;
  return <VenuePlanEditorPage venueId={venueId} />;
}
