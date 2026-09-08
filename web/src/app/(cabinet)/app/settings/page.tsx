import { redirect } from "next/navigation";
import { SettingsHubView } from "@/features/settings/components/settings-hub-view";
import { getCurrentProfile } from "@/features/profile/lib/profile";
import { createClient } from "@/lib/supabase/server";

export default async function SettingsPage() {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) redirect("/auth");

  const profile = await getCurrentProfile();
  const hasBookingTag = Boolean(profile?.tagKeys.includes("booking"));

  return <SettingsHubView hasBookingTag={hasBookingTag} />;
}
