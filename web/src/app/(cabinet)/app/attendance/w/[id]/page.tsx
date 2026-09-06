import { AttendanceWorkerDetailView } from "@/features/attendance/components/attendance-worker-detail-view";

type Props = { params: Promise<{ id: string }> };

export default async function AttendanceWorkerDetailPage({ params }: Props) {
  const { id } = await params;
  return <AttendanceWorkerDetailView workplaceId={id} />;
}
