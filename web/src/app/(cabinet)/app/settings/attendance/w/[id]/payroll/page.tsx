import { AttendancePayrollView } from "@/features/attendance/components/attendance-payroll-view";

type Props = { params: Promise<{ id: string }> };

export default async function AttendancePayrollPage({ params }: Props) {
  const { id } = await params;
  return <AttendancePayrollView workplaceId={id} />;
}
