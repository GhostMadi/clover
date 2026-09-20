"use client";

import { VenuePlanEditorView } from "@/features/venue/components/venue-plan-editor-view";

const NAMES: Record<string, string> = {
  cafe: "Кафе Clover",
  cinema: "Кино Star",
  poetry: "Вечер поэзии",
};

export function VenuePlanEditorPage({ venueId }: { venueId: string }) {
  const name = NAMES[venueId] ?? "Заведение";
  return <VenuePlanEditorView venueId={venueId} venueName={name} />;
}
