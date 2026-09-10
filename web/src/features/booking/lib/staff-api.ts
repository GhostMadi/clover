import { mapStaff, type BookingStaff } from "@/features/booking/lib/booking-model";
import { createClient } from "@/lib/supabase/client";

export async function listMyStaff(activeOnly = true): Promise<BookingStaff[]> {
  const supabase = createClient();
  const {
    data: { session },
  } = await supabase.auth.getSession();
  const user = session?.user ?? null;
  if (!user) return [];
  let q = supabase
    .from("booking_staff")
    .select("*, profiles:profile_id(avatar_url)")
    .eq("host_id", user.id);
  if (activeOnly) q = q.eq("is_active", true);
  const { data, error } = await q.order("sort_order").order("display_name");
  if (error) throw error;
  return (data ?? []).map((row) => mapStaff(row as Record<string, unknown>));
}

export async function createStaffByName(displayName: string): Promise<BookingStaff> {
  const supabase = createClient();
  const {
    data: { session },
  } = await supabase.auth.getSession();
  const user = session?.user ?? null;
  if (!user) throw new Error("Войдите в аккаунт");
  const name = displayName.trim();
  if (!name) throw new Error("Укажите имя мастера");
  const { data, error } = await supabase
    .from("booking_staff")
    .insert({ host_id: user.id, display_name: name })
    .select("*, profiles:profile_id(avatar_url)")
    .single();
  if (error) throw error;
  return mapStaff(data as Record<string, unknown>);
}

export type StaffProfileHit = {
  id: string;
  username: string;
  displayName: string | null;
  avatarUrl: string | null;
};

export type BookingStaffInvite = {
  id: string;
  hostId: string;
  inviteeId: string;
  status: string;
  createdAt: string;
  inviteeDisplayName: string;
  inviteeUsername: string | null;
  inviteeAvatarUrl: string | null;
};

function mapInvite(row: Record<string, unknown>): BookingStaffInvite {
  return {
    id: String(row.id ?? ""),
    hostId: String(row.host_id ?? ""),
    inviteeId: String(row.invitee_id ?? ""),
    status: String(row.status ?? "pending"),
    createdAt: String(row.created_at ?? ""),
    inviteeDisplayName: String(row.invitee_display_name ?? ""),
    inviteeUsername: (row.invitee_username as string | null) ?? null,
    inviteeAvatarUrl: (row.invitee_avatar_url as string | null) ?? null,
  };
}

/** Сообщение для UI из PostgREST / RPC. */
export function staffInviteErrorMessage(error: unknown, fallback = "Не удалось пригласить"): string {
  const raw =
    error instanceof Error
      ? error.message
      : error && typeof error === "object" && "message" in error
        ? String((error as { message?: unknown }).message ?? "")
        : "";
  const code =
    error && typeof error === "object" && "code" in error
      ? String((error as { code?: unknown }).code ?? "")
      : "";
  const text = `${code} ${raw}`.toLowerCase();

  if (text.includes("already_staff") || code === "P0023") {
    return "Этот аккаунт уже в исполнителях";
  }
  if (text.includes("booking_disabled") || text.includes("host_disabled")) {
    return "Нужен тег «Принимаю запись» в профиле";
  }
  if (text.includes("self_booking") || code === "P0027") {
    return "Нельзя пригласить себя";
  }
  if (text.includes("not_found") || code === "P0022") {
    return "Аккаунт не найден";
  }
  if (text.includes("not_authenticated") || code === "P0003") {
    return "Войдите в аккаунт";
  }
  if (text.includes("could not find the function") || text.includes("does not exist")) {
    return "Сервис приглашений ещё не готов — обновите страницу";
  }
  if (raw.trim()) return raw.trim();
  return fallback;
}

export async function searchStaffProfiles(query: string): Promise<StaffProfileHit[]> {
  const supabase = createClient();
  const {
    data: { session },
  } = await supabase.auth.getSession();
  const user = session?.user ?? null;
  if (!user) return [];
  const q = query.trim();
  let builder = supabase
    .from("profiles")
    .select("id, username, full_name, avatar_url")
    .neq("id", user.id);
  if (q) {
    const pattern = `%${q}%`;
    builder = builder.or(`username.ilike.${pattern},full_name.ilike.${pattern}`);
  }
  const { data, error } = await builder.order("username").limit(20);
  if (error) throw error;
  return (data ?? []).map((row) => ({
    id: String(row.id),
    username: String(row.username ?? "noName"),
    displayName: (row.full_name as string | null) ?? null,
    avatarUrl: (row.avatar_url as string | null) ?? null,
  }));
}

/** Invite Clover account via DM. Linked staff is created only after Accept. */
export async function inviteStaff(profileId: string): Promise<string> {
  const supabase = createClient();
  const {
    data: { session },
  } = await supabase.auth.getSession();
  const user = session?.user ?? null;
  if (!user) throw new Error("Войдите в аккаунт");
  const id = profileId.trim();
  if (!id) throw new Error("Не выбран аккаунт");
  const { data, error } = await supabase.rpc("booking_invite_staff", {
    p_profile_id: id,
  });
  if (error) throw new Error(staffInviteErrorMessage(error));
  const inviteId = String(data ?? "").trim();
  if (!inviteId) throw new Error("Не удалось отправить приглашение");
  return inviteId;
}

export async function listPendingStaffInvites(): Promise<BookingStaffInvite[]> {
  const supabase = createClient();
  const {
    data: { session },
  } = await supabase.auth.getSession();
  const user = session?.user ?? null;
  if (!user) return [];
  const { data, error } = await supabase.rpc("list_booking_staff_invites_pending");
  if (error) throw error;
  if (!Array.isArray(data)) return [];
  return data
    .map((raw) => mapInvite(raw as Record<string, unknown>))
    .filter((inv) => inv.id.length > 0);
}

export async function cancelStaffInvite(inviteId: string): Promise<void> {
  const id = inviteId.trim();
  if (!id) throw new Error("Нет заявки");
  const supabase = createClient();
  const { error } = await supabase.rpc("booking_cancel_staff_invite", {
    p_invite_id: id,
  });
  if (error) throw error;
}

export async function acceptStaffInvite(inviteId: string): Promise<void> {
  const id = inviteId.trim();
  if (!id) throw new Error("Нет заявки");
  const supabase = createClient();
  const { error } = await supabase.rpc("booking_accept_staff_invite", {
    p_invite_id: id,
  });
  if (error) throw error;
}

export async function rejectStaffInvite(inviteId: string): Promise<void> {
  const id = inviteId.trim();
  if (!id) throw new Error("Нет заявки");
  const supabase = createClient();
  const { error } = await supabase.rpc("booking_reject_staff_invite", {
    p_invite_id: id,
  });
  if (error) throw error;
}

export async function setStaffActive(staffId: string, isActive: boolean): Promise<void> {
  const supabase = createClient();
  const {
    data: { session },
  } = await supabase.auth.getSession();
  const user = session?.user ?? null;
  if (!user) throw new Error("Войдите в аккаунт");
  const { error } = await supabase
    .from("booking_staff")
    .update({ is_active: isActive })
    .eq("id", staffId)
    .eq("host_id", user.id);
  if (error) throw error;
}
