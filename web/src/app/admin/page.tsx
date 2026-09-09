import { redirect } from "next/navigation";
import { AdminLoginForm } from "@/features/admin/components/admin-login-form";
import { getAdminSessionFromCookies } from "@/lib/admin-auth";

export default async function AdminLoginPage() {
  const session = await getAdminSessionFromCookies();
  if (session) redirect("/admin/home");

  return (
    <main className="mx-auto flex min-h-dvh w-full max-w-md flex-col justify-center gap-6 px-5 py-10">
      <div>
        <p className="text-[13px] font-semibold text-brand">Clover</p>
        <h1 className="mt-1 text-[24px] font-bold tracking-tight text-ink">Админка</h1>
        <p className="mt-2 text-[14px] text-muted">Вход только для оператора сайта.</p>
      </div>
      <AdminLoginForm />
    </main>
  );
}
