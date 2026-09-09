import { redirect } from "next/navigation";
import { AttendanceWorkerHubView } from "@/features/attendance/components/attendance-worker-hub-view";
import { getCurrentProfile } from "@/features/profile/lib/profile";
import { createClient } from "@/lib/supabase/server";

export default async function AttendanceWorkerPage() {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) redirect("/auth");

  const profile = await getCurrentProfile();
  if (!profile?.tagKeys.includes("attendanceWork")) {
    redirect("/app/profile");
  }

  return <AttendanceWorkerHubView />;
}
