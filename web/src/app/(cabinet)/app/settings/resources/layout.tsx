import { redirect } from "next/navigation";
import { getCurrentProfile } from "@/features/profile/lib/profile";
import { createClient } from "@/lib/supabase/server";

export default async function ResourcesSettingsLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const supabase = await createClient();
  const {
    data: { session },
  } = await supabase.auth.getSession();
  const user = session?.user ?? null;
  if (!user) redirect("/auth");

  const profile = await getCurrentProfile();
  if (!profile?.tagKeys.includes("resources")) {
    redirect("/app/settings");
  }

  return children;
}
