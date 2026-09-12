import { createClient, getAuthUser } from "@/lib/supabase/server";

/**
 * Админ сайта = обычный Supabase-аккаунт с profiles.is_site_admin.
 * Отдельный env ADMIN_SESSION_SECRET не нужен — сессия = cookie Auth.
 */
export async function getSiteAdminEmail(): Promise<string | null> {
  const user = await getAuthUser();
  if (!user?.email) return null;

  const supabase = await createClient();
  const { data: isAdmin, error } = await supabase.rpc("is_site_admin");
  if (error || !isAdmin) return null;

  return user.email.trim().toLowerCase();
}

/** Совместимость со старыми импортами. */
export async function getAdminSessionFromCookies(): Promise<string | null> {
  return getSiteAdminEmail();
}

/** Назначение админа через UI выключено. */
export function isAdminRegisterAllowed(): boolean {
  return false;
}
