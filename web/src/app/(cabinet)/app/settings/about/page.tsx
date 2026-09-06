import { redirect } from "next/navigation";
import { SettingsAboutView } from "@/features/settings/components/settings-about-view";
import { createClient } from "@/lib/supabase/server";

export default async function SettingsAboutPage() {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) redirect("/auth");
  return <SettingsAboutView />;
}
