import { redirect } from "next/navigation";
import { FollowListView } from "@/features/profile/components/follow-list-view";
import { createClient } from "@/lib/supabase/server";

type PageProps = {
  params: Promise<{ userId: string }>;
  searchParams: Promise<{ tab?: string }>;
};

export default async function UserSocialPage({ params, searchParams }: PageProps) {
  const { userId } = await params;
  const { tab } = await searchParams;
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) redirect("/auth");

  const mode = tab === "following" ? "following" : "followers";
  const isOwn = user.id === userId;
  const backHref = isOwn ? "/app/profile" : `/app/u/${userId}`;

  return (
    <FollowListView
      profileId={userId}
      mode={mode}
      backHref={backHref}
      title={mode === "followers" ? "Подписчики" : "Подписки"}
    />
  );
}
