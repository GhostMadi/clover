import { redirect } from "next/navigation";
import { ClusterArchiveView } from "@/features/settings/components/cluster-archive-view";
import { createClient } from "@/lib/supabase/server";

export default async function ClusterArchivePage() {
  const supabase = await createClient();
  const {
    data: { session },
  } = await supabase.auth.getSession();
  const user = session?.user ?? null;
  if (!user) redirect("/auth");
  return <ClusterArchiveView />;
}
