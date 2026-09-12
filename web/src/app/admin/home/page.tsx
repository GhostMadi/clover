import Link from "next/link";
import { redirect } from "next/navigation";
import { AdminLogoutButton } from "@/features/admin/components/admin-logout-button";
import { getAdminSessionFromCookies } from "@/lib/admin-auth";

export default async function AdminHomePage() {
  const email = await getAdminSessionFromCookies();
  if (!email) redirect("/admin");

  return (
    <main className="mx-auto flex min-h-dvh w-full max-w-2xl flex-col gap-6 px-5 py-10">
      <header className="flex flex-wrap items-start justify-between gap-3">
        <div>
          <p className="text-[13px] font-semibold text-brand">Clover Admin</p>
          <h1 className="mt-1 text-[24px] font-bold tracking-tight text-ink">Панель администратора</h1>
          <p className="mt-2 text-[14px] text-muted">Вы вошли как {email}</p>
        </div>
        <AdminLogoutButton />
      </header>

      <section className="rounded-[16px] border border-brand/30 bg-surface p-5 shadow-elevate-brand/20">
        <p className="text-[12px] font-semibold uppercase tracking-wide text-brand">Статус</p>
        <h2 className="mt-1 text-[18px] font-bold text-ink">Вход выполнен</h2>
        <p className="mt-2 text-[14px] leading-relaxed text-muted">
          Это служебная админка сайта. Аккаунт отмечен как{" "}
          <span className="font-semibold text-ink">site admin</span> (
          <code className="text-[12px]">profiles.is_site_admin</code>).
        </p>
      </section>

      <section className="grid gap-3 sm:grid-cols-2">
        <Link
          href="/admin/honest"
          className="rounded-[16px] border border-brand/40 bg-mint/30 p-4 transition hover:border-brand"
        >
          <h3 className="text-[15px] font-bold text-ink">Честный тест</h3>
          <p className="mt-1 text-[13px] text-muted">Ответы и фото (временно)</p>
        </Link>
        <Link
          href="/app"
          className="rounded-[16px] border border-line bg-surface p-4 transition hover:border-brand/40"
        >
          <h3 className="text-[15px] font-bold text-ink">Кабинет</h3>
          <p className="mt-1 text-[13px] text-muted">Открыть обычный /app под этим же аккаунтом</p>
        </Link>
      </section>
    </main>
  );
}
