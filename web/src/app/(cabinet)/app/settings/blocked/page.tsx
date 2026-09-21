import { redirect } from "next/navigation";
import { SettingsBlockedView } from "@/features/settings/components/settings-blocked-view";
import { createClient } from "@/lib/supabase/server";

export default async function SettingsBlockedPage() {
  const supabase = await createClient();
  const {
    data: { session },
  } = await supabase.auth.getSession();
  const user = session?.user ?? null;
  if (!user) redirect("/auth");
  return <SettingsBlockedView />;
}
