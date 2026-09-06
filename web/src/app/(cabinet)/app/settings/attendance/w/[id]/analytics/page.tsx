import { AttendanceAnalyticsView } from "@/features/attendance/components/attendance-analytics-view";

type Props = { params: Promise<{ id: string }> };

export default async function AttendanceAnalyticsPage({ params }: Props) {
  const { id } = await params;
  return <AttendanceAnalyticsView workplaceId={id} />;
}
