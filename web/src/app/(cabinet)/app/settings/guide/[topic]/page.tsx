import { notFound } from "next/navigation";
import { ServicesGuideTopicView } from "@/features/settings/components/services-guide-topic-view";
import { getServicesGuide } from "@/features/settings/lib/services-guide";

type Props = {
  params: Promise<{ topic: string }>;
};

export default async function SettingsGuideTopicPage({ params }: Props) {
  const { topic } = await params;
  const content = getServicesGuide(topic);
  if (!content) notFound();
  return <ServicesGuideTopicView content={content} />;
}
