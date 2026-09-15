import { AttendanceCorrectionsView } from "@/features/attendance/components/attendance-corrections-view";

type Props = { params: Promise<{ id: string }> };

export default async function AttendanceCorrectionsPage({ params }: Props) {
  const { id } = await params;
  return <AttendanceCorrectionsView workplaceId={id} />;
}
