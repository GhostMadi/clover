import { redirect } from "next/navigation";
import { BookingHubView } from "@/features/booking/components/booking-hub-view";
import { getCurrentProfile } from "@/features/profile/lib/profile";
import { createClient } from "@/lib/supabase/server";

export default async function BookingSettingsPage() {
  const supabase = await createClient();
  const {
    data: { session },
  } = await supabase.auth.getSession();
  const user = session?.user ?? null;
  if (!user) redirect("/auth");

  const profile = await getCurrentProfile();
  if (!profile?.tagKeys.includes("booking")) {
    redirect("/app/settings/booking/my");
  }

  return <BookingHubView />;
}
