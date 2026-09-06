import { AttendanceWorkplaceHubView } from "@/features/attendance/components/attendance-workplace-hub-view";

type Props = { params: Promise<{ id: string }> };

export default async function AttendanceWorkplacePage({ params }: Props) {
  const { id } = await params;
  return <AttendanceWorkplaceHubView workplaceId={id} />;
}
