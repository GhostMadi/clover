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
 * Сон аккаунта (RPC hibernate) + выход.
 * Это не удаление и не wipe — см. docs/business/account-sleep.md.
 */
export async function hibernateAccount(): Promise<void> {
  const supabase = createClient();
  const { error } = await supabase.rpc("hibernate_account");
  if (error) {
    const msg = error.message || "";
    if (msg.includes("hibernate_rate_limited")) {
      throw new Error("Сон доступен раз в 30 дней. Попробуйте позже.");
    }
    throw new Error(msg || "Не удалось усыпить аккаунт");
  }
  await signOut();
}
