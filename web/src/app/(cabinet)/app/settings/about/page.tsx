import { redirect } from "next/navigation";
import { SettingsAboutView } from "@/features/settings/components/settings-about-view";
import { createClient } from "@/lib/supabase/server";

export default async function SettingsAboutPage() {
  const supabase = await createClient();
  const {
    data: { session },
  } = await supabase.auth.getSession();
  const user = session?.user ?? null;
  if (!user) redirect("/auth");
  return <SettingsAboutView />;
}
