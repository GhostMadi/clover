import { redirect } from "next/navigation";
import { BookingPointsView } from "@/features/booking/components/booking-points-view";
import { getCurrentProfile } from "@/features/profile/lib/profile";
import { createClient } from "@/lib/supabase/server";

export default async function BookingPointsPage() {
  const supabase = await createClient();
  const {
    data: { session },
  } = await supabase.auth.getSession();
  if (!session?.user) redirect("/auth");

  const profile = await getCurrentProfile();
  if (!profile?.tagKeys.includes("booking")) {
    redirect("/app/settings");
  }

  return <BookingPointsView />;
}
