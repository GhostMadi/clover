import { AttendanceGuideView } from "@/features/attendance/components/attendance-guide-view";

type Props = {
  params: Promise<{ id: string }>;
};

export default async function AttendanceGuidePage({ params }: Props) {
  const { id } = await params;
  return <AttendanceGuideView workplaceId={id} />;
}
