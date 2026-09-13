import { NextResponse } from "next/server";
import type { SupabaseClient } from "@supabase/supabase-js";
import { getAdminSessionFromCookies } from "@/lib/admin-auth";
import { createServiceRoleClient } from "@/lib/supabase/service-role";

export type SiteAdminApiOk = {
  ok: true;
  email: string;
  supabase: SupabaseClient;
};

export type SiteAdminApiFail = {
  ok: false;
  response: NextResponse;
};

/** Cookie session + live profiles.is_site_admin via service_role. */
export async function requireSiteAdminApi(): Promise<SiteAdminApiOk | SiteAdminApiFail> {
  const email = await getAdminSessionFromCookies();
  if (!email) {
    return {
      ok: false,
      response: NextResponse.json({ error: "unauthorized" }, { status: 401 }),
    };
  }

  let supabase: SupabaseClient;
  try {
    supabase = createServiceRoleClient();
  } catch {
    return {
      ok: false,
      response: NextResponse.json(
        { error: "Админка не настроена (нет SUPABASE_SERVICE_ROLE_KEY)" },
        { status: 503 },
      ),
    };
  }

  const { data: profile, error } = await supabase
    .from("profiles")
    .select("id, is_site_admin")
    .eq("email", email)
    .maybeSingle();

  if (error) {
    return {
      ok: false,
      response: NextResponse.json({ error: error.message }, { status: 500 }),
    };
  }

  if (!profile?.is_site_admin) {
    return {
      ok: false,
      response: NextResponse.json({ error: "forbidden" }, { status: 403 }),
    };
  }

  return { ok: true, email, supabase };
}
