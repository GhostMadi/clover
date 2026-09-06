import { AttendanceGeofenceView } from "@/features/attendance/components/attendance-geofence-view";

type Props = { params: Promise<{ id: string }> };

export default async function AttendanceGeofencePage({ params }: Props) {
  const { id } = await params;
  return <AttendanceGeofenceView workplaceId={id} />;
}
