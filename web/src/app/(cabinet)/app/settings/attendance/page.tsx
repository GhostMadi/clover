import { redirect } from "next/navigation";
import { AttendanceEntryRedirect } from "@/features/attendance/components/attendance-entry-redirect";
import { getCurrentProfile } from "@/features/profile/lib/profile";
import { createClient } from "@/lib/supabase/server";

/** Вход в посещаемость → last/first компания (кэш). */
export default async function AttendanceSettingsPage() {
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

  return <AttendanceEntryRedirect />;
}
