"use client";

import { createClient } from "@/lib/supabase/client";
import { signOut } from "@/features/auth/lib/auth-api";

/**
 * Деактивация аккаунта (RPC hibernate) + выход.
 * Полный wipe контента на бэке отключён — см. docs/supabase.
 */
export async function deleteAccount(): Promise<void> {
  const supabase = createClient();
  const { error } = await supabase.rpc("hibernate_account");
  if (error) {
    throw new Error(error.message || "Не удалось удалить аккаунт");
  }
  await signOut();
}
