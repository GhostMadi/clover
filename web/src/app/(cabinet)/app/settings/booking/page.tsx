import { redirect } from "next/navigation";
import { BookingEntryRedirect } from "@/features/booking/components/booking-entry-redirect";
import { getCurrentProfile } from "@/features/profile/lib/profile";
import { createClient } from "@/lib/supabase/server";

export default async function BookingSettingsPage() {
  const supabase = await createClient();
  const {
    data: { session },
  } = await supabase.auth.getSession();
  if (!session?.user) redirect("/auth");

  const profile = await getCurrentProfile();
  if (!profile?.tagKeys.includes("booking")) {
    redirect("/app/settings");
  }

  return <BookingEntryRedirect />;
}
