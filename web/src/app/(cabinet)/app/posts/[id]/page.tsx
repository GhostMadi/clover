import { notFound } from "next/navigation";
import { PostDetailView } from "@/features/post/components/post-detail-view";
import { getPostEnriched } from "@/features/post/lib/get-post";
import { createClient } from "@/lib/supabase/server";

type PageProps = {
  params: Promise<{ id: string }>;
};

export default async function PostPage({ params }: PageProps) {
  const { id: raw } = await params;
  const id = raw?.trim() ?? "";
  if (!id) notFound();

  const supabase = await createClient();
  const [{ data: sessionData }, post] = await Promise.all([
    supabase.auth.getSession(),
    getPostEnriched(id),
  ]);

  if (!post) notFound();

  return (
    <PostDetailView
      post={post}
      currentUserId={sessionData.session?.user.id ?? null}
    />
  );
}
