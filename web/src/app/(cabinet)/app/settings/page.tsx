import { redirect } from "next/navigation";
import { SettingsHubView } from "@/features/settings/components/settings-hub-view";
import { createClient } from "@/lib/supabase/server";

export default async function SettingsPage() {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) redirect("/auth");
  return <SettingsHubView />;
}
