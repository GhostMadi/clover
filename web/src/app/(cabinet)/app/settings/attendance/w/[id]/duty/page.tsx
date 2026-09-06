import { AttendanceDutyView } from "@/features/attendance/components/attendance-duty-view";

type Props = { params: Promise<{ id: string }> };

export default async function AttendanceDutyPage({ params }: Props) {
  const { id } = await params;
  return <AttendanceDutyView workplaceId={id} />;
}
