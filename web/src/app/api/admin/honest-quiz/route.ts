import { NextResponse } from "next/server";
import { requireSiteAdminApi } from "@/lib/admin-api-guard";

/** Список / деталь прохождений — cookie + service_role. */
export async function GET(request: Request) {
  const gate = await requireSiteAdminApi();
  if (!gate.ok) return gate.response;

  const { searchParams } = new URL(request.url);
  const id = searchParams.get("id")?.trim();

  if (id) {
    const { data, error } = await gate.supabase.rpc("honest_quiz_admin_get", {
      p_id: id,
    });
    if (error) {
      return NextResponse.json({ error: error.message }, { status: 400 });
    }
    return NextResponse.json({ run: data });
  }

  const { data, error } = await gate.supabase.rpc("honest_quiz_admin_list");
  if (error) {
    return NextResponse.json({ error: error.message }, { status: 400 });
  }
  return NextResponse.json({ runs: Array.isArray(data) ? data : [] });
}
