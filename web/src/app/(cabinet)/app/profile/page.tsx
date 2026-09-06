import { redirect } from "next/navigation";
import { ProfileView } from "@/features/profile/components/profile-view";
import { listUserClustersServer } from "@/features/profile/lib/clusters-server";
import { getProfileById } from "@/features/profile/lib/profile";
import { listProfilePosts } from "@/features/profile/lib/posts";
import { createClient } from "@/lib/supabase/server";

export default async function AppProfilePage() {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) redirect("/auth");

  const [profile, posts, clusters] = await Promise.all([
    getProfileById(user.id, user.email),
    listProfilePosts(user.id),
    listUserClustersServer(user.id),
  ]);

  return <ProfileView profile={profile} posts={posts} clusters={clusters} />;
}
