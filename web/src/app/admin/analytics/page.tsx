import Link from "next/link";
import { redirect } from "next/navigation";
import { AdminAnalyticsCards } from "@/features/admin/components/admin-analytics-cards";
import { getAdminSessionFromCookies } from "@/lib/admin-auth";

export default async function AdminAnalyticsPage() {
  const email = await getAdminSessionFromCookies();
  if (!email) redirect("/admin");

  return (
    <main className="mx-auto flex min-h-dvh w-full max-w-2xl flex-col gap-6 px-5 py-10">
      <header className="flex flex-wrap items-center justify-between gap-3">
        <div>
          <p className="text-[13px] font-semibold text-brand">Clover Admin</p>
          <h1 className="mt-1 text-[24px] font-bold tracking-tight text-ink">Аналитика</h1>
          <p className="mt-1 text-[13px] text-muted">Платформа, не host booking</p>
        </div>
        <Link
          href="/admin/home"
          className="rounded-[12px] border border-line px-3 py-2 text-[13px] font-semibold text-ink"
        >
          ← Хаб
        </Link>
      </header>

      <AdminAnalyticsCards />
    </main>
  );
}
