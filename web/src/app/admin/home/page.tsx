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
          <h1 className="mt-1 text-[24px] font-bold tracking-tight text-ink">Панель</h1>
          <p className="mt-2 text-[14px] text-muted">Вы вошли как {email}</p>
        </div>
        <AdminLogoutButton />
      </header>

      <section className="rounded-[16px] border border-line bg-surface p-4">
        <h2 className="text-[15px] font-bold text-ink">Пока пусто</h2>
        <p className="mt-1 text-[14px] text-muted">
          Сюда добавим служебные инструменты сайта. Вход и сессия уже работают.
        </p>
      </section>
    </main>
  );
}
