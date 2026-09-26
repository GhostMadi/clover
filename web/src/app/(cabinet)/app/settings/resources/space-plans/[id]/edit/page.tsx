import { SpacePlanEditorPage } from "@/features/resources/components/space-plan-editor-page";

type Props = { params: Promise<{ id: string }> };

export default async function ResourcesSpacePlanEditPage({ params }: Props) {
  const { id } = await params;
  return <SpacePlanEditorPage planId={id} />;
}
