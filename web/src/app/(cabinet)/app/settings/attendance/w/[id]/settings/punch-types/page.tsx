import { AttendancePunchTypesView } from "@/features/attendance/components/attendance-punch-types-view";

type Props = { params: Promise<{ id: string }> };

export default async function AttendancePunchTypesPage({ params }: Props) {
  const { id } = await params;
  return <AttendancePunchTypesView workplaceId={id} />;
}
