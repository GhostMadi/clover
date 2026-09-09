import { redirect } from "next/navigation";
import { AttendanceHubView } from "@/features/attendance/components/attendance-hub-view";
import { getCurrentProfile } from "@/features/profile/lib/profile";
import { createClient } from "@/lib/supabase/server";

export default async function AttendanceSettingsPage() {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) redirect("/auth");

  const profile = await getCurrentProfile();
  if (!profile?.tagKeys.includes("attendance")) {
    redirect("/app/settings");
  }

  return <AttendanceHubView />;
}
