import { redirect } from "next/navigation";
import { EditProfileView } from "@/features/profile/components/edit-profile-view";
import { getProfileById } from "@/features/profile/lib/profile";
import { createClient } from "@/lib/supabase/server";

export default async function EditProfilePage() {
  const supabase = await createClient();
  const {
    data: { session },
  } = await supabase.auth.getSession();
  const user = session?.user ?? null;
  if (!user) redirect("/auth");

  const profile = await getProfileById(user.id, user.email);
  return <EditProfileView profile={profile} />;
}
