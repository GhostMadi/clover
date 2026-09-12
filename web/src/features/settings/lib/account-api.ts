"use client";

import { createClient } from "@/lib/supabase/client";
import { signOut } from "@/features/auth/lib/auth-api";

export type LoginEvent = {
  id: string;
  client: string;
  platform: string;
  deviceLabel: string | null;
  role: "primary" | "guest" | string;
  status: "active" | "confirmed" | "revoked" | string;
  createdAt: string;
};

export async function listMyLoginEvents(limit = 12): Promise<LoginEvent[]> {
  const supabase = createClient();
  const { data, error } = await supabase.rpc("list_my_login_events", {
    p_limit: limit,
  });
  if (error) throw error;
  const rows = Array.isArray(data) ? data : [];
  return rows
    .map((raw) => {
      const r = raw as Record<string, unknown>;
      return {
        id: String(r.id ?? ""),
        client: String(r.client ?? ""),
        platform: String(r.platform ?? ""),
        deviceLabel: (r.device_label as string | null)?.trim() || null,
        role: String(r.role ?? "guest"),
        status: String(r.status ?? "active"),
        createdAt: String(r.created_at ?? ""),
      };
    })
    .filter((e) => e.id);
}

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
