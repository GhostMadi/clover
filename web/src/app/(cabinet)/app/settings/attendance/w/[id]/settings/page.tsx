import { AttendanceSettingsHubView } from "@/features/attendance/components/attendance-settings-hub-view";

type Props = { params: Promise<{ id: string }> };

export default async function AttendanceWorkplaceSettingsPage({ params }: Props) {
  const { id } = await params;
  return <AttendanceSettingsHubView workplaceId={id} />;
}
