import { AttendanceMembersView } from "@/features/attendance/components/attendance-members-view";

type Props = { params: Promise<{ id: string }> };

export default async function AttendanceWorkplaceMembersPage({ params }: Props) {
  const { id } = await params;
  return <AttendanceMembersView workplaceId={id} />;
}
