import { redirect } from "next/navigation";
import { AttendanceWorkerDetailView } from "@/features/attendance/components/attendance-worker-detail-view";
import { getCurrentProfile } from "@/features/profile/lib/profile";
import { createClient } from "@/lib/supabase/server";

type Props = { params: Promise<{ id: string }> };

export default async function AttendanceWorkerDetailPage({ params }: Props) {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) redirect("/auth");

  const profile = await getCurrentProfile();
  if (!profile?.tagKeys.includes("attendanceWork")) {
    redirect("/app/profile");
  }

  const { id } = await params;
  return <AttendanceWorkerDetailView workplaceId={id} />;
}
