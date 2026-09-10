import { redirect } from "next/navigation";
import { SavedPostsView } from "@/features/settings/components/saved-posts-view";
import { createClient } from "@/lib/supabase/server";

export default async function SavedPostsPage() {
  const supabase = await createClient();
  const {
    data: { session },
  } = await supabase.auth.getSession();
  const user = session?.user ?? null;
  if (!user) redirect("/auth");
  return <SavedPostsView />;
}
