import { mapStaff, type BookingStaff } from "@/features/booking/lib/booking-model";
import { createClient } from "@/lib/supabase/client";

export async function listMyStaff(activeOnly = true): Promise<BookingStaff[]> {
  const supabase = createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
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
    data: { user },
  } = await supabase.auth.getUser();
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

export async function searchStaffProfiles(query: string): Promise<StaffProfileHit[]> {
  const supabase = createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
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

export async function ensureStaffFromProfile(profileId: string): Promise<BookingStaff> {
  const supabase = createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) throw new Error("Войдите в аккаунт");
  const id = profileId.trim();
  const { data: existing } = await supabase
    .from("booking_staff")
    .select("*, profiles:profile_id(avatar_url)")
    .eq("host_id", user.id)
    .eq("profile_id", id)
    .maybeSingle();
  if (existing) return mapStaff(existing as Record<string, unknown>);

  const { data: profile, error: pErr } = await supabase
    .from("profiles")
    .select("id, username, full_name, avatar_url")
    .eq("id", id)
    .maybeSingle();
  if (pErr) throw pErr;
  if (!profile) throw new Error("Профиль не найден");

  const display =
    (profile.full_name as string | null)?.trim() ||
    (profile.username as string | null)?.trim() ||
    "Мастер";

  const { data, error } = await supabase
    .from("booking_staff")
    .insert({
      host_id: user.id,
      profile_id: id,
      display_name: display,
      username: profile.username,
    })
    .select("*, profiles:profile_id(avatar_url)")
    .single();
  if (error) throw error;
  return mapStaff(data as Record<string, unknown>);
}

export async function setStaffActive(staffId: string, isActive: boolean): Promise<void> {
  const supabase = createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) throw new Error("Войдите в аккаунт");
  const { error } = await supabase
    .from("booking_staff")
    .update({ is_active: isActive })
    .eq("id", staffId)
    .eq("host_id", user.id);
  if (error) throw error;
}
