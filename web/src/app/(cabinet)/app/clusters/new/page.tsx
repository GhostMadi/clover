import { redirect } from "next/navigation";
import { CreateClusterFlow } from "@/features/profile/components/create-cluster-flow";
import { createClient } from "@/lib/supabase/server";

export default async function NewClusterPage() {
  const supabase = await createClient();
  const {
    data: { session },
  } = await supabase.auth.getSession();
  const user = session?.user ?? null;
  if (!user) redirect("/auth");
  return <CreateClusterFlow />;
}
