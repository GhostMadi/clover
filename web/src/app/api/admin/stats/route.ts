import { NextResponse } from "next/server";
import { requireSiteAdminApi } from "@/lib/admin-api-guard";

/** Platform KPIs: ?days=1|7|30 */
export async function GET(request: Request) {
  const gate = await requireSiteAdminApi();
  if (!gate.ok) return gate.response;

  const raw = new URL(request.url).searchParams.get("days");
  const parsed = raw ? Number.parseInt(raw, 10) : 7;
  const days = parsed === 1 || parsed === 30 ? parsed : 7;

  const { data, error } = await gate.supabase.rpc("admin_platform_stats", {
    p_days: days,
  });

  if (error) {
    return NextResponse.json({ error: error.message }, { status: 400 });
  }

  return NextResponse.json({ stats: data ?? {} });
}
