import { redirect } from "next/navigation";
import { HonestQuizAdminView } from "@/features/honest-quiz/components/honest-quiz-admin-view";
import { getAdminSessionFromCookies } from "@/lib/admin-auth";

export default async function AdminHonestPage() {
  const email = await getAdminSessionFromCookies();
  if (!email) redirect("/admin");

  return <HonestQuizAdminView />;
}
