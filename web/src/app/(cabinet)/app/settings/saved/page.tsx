import { redirect } from "next/navigation";
import { SavedPostsView } from "@/features/settings/components/saved-posts-view";
import { createClient } from "@/lib/supabase/server";

export default async function SavedPostsPage() {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) redirect("/auth");
  return <SavedPostsView />;
}
