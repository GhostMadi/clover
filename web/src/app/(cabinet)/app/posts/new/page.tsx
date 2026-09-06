import { redirect } from "next/navigation";
import { CreatePostFlow } from "@/features/post-create/components/create-post-flow";
import { createClient } from "@/lib/supabase/server";

export default async function NewPostPage() {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) redirect("/auth");

  return <CreatePostFlow />;
}
