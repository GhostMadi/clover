import { notFound, redirect } from "next/navigation";
import { ClientBookFlow } from "@/features/booking/components/client-book-flow";
import { getProfileById } from "@/features/profile/lib/profile";
import { createClient } from "@/lib/supabase/server";

type PageProps = {
  params: Promise<{ userId: string }>;
  searchParams: Promise<{ service?: string }>;
};

export default async function BookHostPage({ params, searchParams }: PageProps) {
  const { userId: raw } = await params;
  const { service } = await searchParams;
  const userId = raw?.trim() ?? "";
  if (!userId) notFound();

  const supabase = await createClient();
  const {
    data: { session },
  } = await supabase.auth.getSession();
  const me = session?.user.id ?? null;
  if (me && me === userId) redirect(`/app/u/${userId}`);

  const profile = await getProfileById(userId);
  if (!profile.tagKeys.includes("booking")) {
    redirect(`/app/u/${userId}`);
  }

  const hostName =
    profile.fullName?.trim() ||
    (profile.username ? `@${profile.username}` : "Хозяин");

  return (
    <ClientBookFlow
      hostId={userId}
      hostName={hostName}
      presetServiceId={service?.trim() || null}
    />
  );
}
