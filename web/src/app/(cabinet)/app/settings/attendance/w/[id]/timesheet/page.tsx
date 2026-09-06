import { AttendanceTimesheetView } from "@/features/attendance/components/attendance-timesheet-view";

type Props = { params: Promise<{ id: string }> };

export default async function AttendanceTimesheetPage({ params }: Props) {
  const { id } = await params;
  return <AttendanceTimesheetView workplaceId={id} />;
}
