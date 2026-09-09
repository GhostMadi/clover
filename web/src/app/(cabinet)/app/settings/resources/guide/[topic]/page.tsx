import { notFound } from "next/navigation";
import { ResourcesGuideView } from "@/features/resources/components/resources-guide-view";
import { getResourcesGuide } from "@/features/resources/lib/resources-guide";

type Props = {
  params: Promise<{ topic: string }>;
};

export default async function ResourcesGuidePage({ params }: Props) {
  const { topic } = await params;
  const content = getResourcesGuide(topic);
  if (!content) notFound();
  return <ResourcesGuideView content={content} />;
}
