import { redirect } from "next/navigation";
import { SettingsAccountView } from "@/features/settings/components/settings-account-view";
import { createClient } from "@/lib/supabase/server";

export default async function SettingsAccountPage() {
  const supabase = await createClient();
  const {
    data: { session },
  } = await supabase.auth.getSession();
  const user = session?.user ?? null;
  if (!user) redirect("/auth");
  return <SettingsAccountView />;
}
