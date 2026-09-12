import { AttendanceTodayView } from "@/features/attendance/components/attendance-today-view";

type Props = { params: Promise<{ id: string }> };

export default async function AttendanceWorkplacePage({ params }: Props) {
  const { id } = await params;
  return <AttendanceTodayView workplaceId={id} />;
}
