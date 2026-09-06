import { redirect } from "next/navigation";
import { SettingsAccountView } from "@/features/settings/components/settings-account-view";
import { createClient } from "@/lib/supabase/server";

export default async function SettingsAccountPage() {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) redirect("/auth");
  return <SettingsAccountView />;
}
