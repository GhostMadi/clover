import { redirect } from "next/navigation";
import { CreateClusterFlow } from "@/features/profile/components/create-cluster-flow";
import { createClient } from "@/lib/supabase/server";

export default async function NewClusterPage() {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) redirect("/auth");
  return <CreateClusterFlow />;
}
