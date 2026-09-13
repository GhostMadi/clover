import { NextResponse } from "next/server";
import { requireSiteAdminApi } from "@/lib/admin-api-guard";

const STATUSES = new Set(["new", "in_progress", "done"]);

/** List support requests (newest first). */
export async function GET() {
  const gate = await requireSiteAdminApi();
  if (!gate.ok) return gate.response;

  const { data, error } = await gate.supabase
    .from("support_requests")
    .select("id, created_at, contact, message, user_id, source, status")
    .order("created_at", { ascending: false })
    .limit(200);

  if (error) {
    return NextResponse.json({ error: error.message }, { status: 400 });
  }

  return NextResponse.json({ items: data ?? [] });
}

/** Update status: { id, status }. */
export async function PATCH(request: Request) {
  const gate = await requireSiteAdminApi();
  if (!gate.ok) return gate.response;

  let body: { id?: string; status?: string };
  try {
    body = (await request.json()) as { id?: string; status?: string };
  } catch {
    return NextResponse.json({ error: "Некорректный запрос" }, { status: 400 });
  }

  const id = typeof body.id === "string" ? body.id.trim() : "";
  const status = typeof body.status === "string" ? body.status.trim() : "";
  if (!id || !STATUSES.has(status)) {
    return NextResponse.json({ error: "Нужны id и status (new|in_progress|done)" }, { status: 400 });
  }

  const { data, error } = await gate.supabase
    .from("support_requests")
    .update({ status })
    .eq("id", id)
    .select("id, created_at, contact, message, user_id, source, status")
    .maybeSingle();

  if (error) {
    return NextResponse.json({ error: error.message }, { status: 400 });
  }
  if (!data) {
    return NextResponse.json({ error: "not_found" }, { status: 404 });
  }

  return NextResponse.json({ item: data });
}
