import { redirect } from "next/navigation";
import { AttendanceHubView } from "@/features/attendance/components/attendance-hub-view";
import { getCurrentProfile } from "@/features/profile/lib/profile";
import { createClient } from "@/lib/supabase/server";

/** Список / создание компаний (не день ops). */
export default async function AttendanceCompaniesPage() {
  const supabase = await createClient();
  const {
    data: { session },
  } = await supabase.auth.getSession();
  const user = session?.user ?? null;
  if (!user) redirect("/auth");

  const profile = await getCurrentProfile();
  if (!profile?.tagKeys.includes("attendance")) {
    redirect("/app/settings");
  }

  return <AttendanceHubView />;
}
