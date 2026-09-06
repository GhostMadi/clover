import { notFound, redirect } from "next/navigation";
import { getIsFollowingUser } from "@/features/catalog/lib/social-server";
import { ProfileView } from "@/features/profile/components/profile-view";
import { listUserClustersServer } from "@/features/profile/lib/clusters-server";
import { getProfileById } from "@/features/profile/lib/profile";
import { listProfilePosts } from "@/features/profile/lib/posts";
import { createClient } from "@/lib/supabase/server";

type PageProps = {
  params: Promise<{ userId: string }>;
};

export default async function GuestProfilePage({ params }: PageProps) {
  const { userId: raw } = await params;
  const userId = raw?.trim() ?? "";
  if (!userId) notFound();

  const supabase = await createClient();
  const {
    data: { session },
  } = await supabase.auth.getSession();
  const me = session?.user.id ?? null;
  if (me && me === userId) redirect("/app/profile");

  const [profile, posts, isFollowing, clusters] = await Promise.all([
    getProfileById(userId),
    listProfilePosts(userId),
    me ? getIsFollowingUser(userId) : Promise.resolve(false),
    listUserClustersServer(userId),
  ]);

  return (
    <ProfileView
      profile={profile}
      posts={posts}
      clusters={clusters}
      mode="guest"
      initialFollowing={isFollowing}
    />
  );
}
