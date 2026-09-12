import { redirect } from "next/navigation";
import { PostArchiveView } from "@/features/settings/components/post-archive-view";
import { createClient } from "@/lib/supabase/server";

export default async function PostArchivePage() {
  const supabase = await createClient();
  const {
    data: { session },
  } = await supabase.auth.getSession();
  const user = session?.user ?? null;
  if (!user) redirect("/auth");
  return <PostArchiveView />;
}
