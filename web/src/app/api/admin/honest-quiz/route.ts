import { NextResponse } from "next/server";
import { createClient } from "@/lib/supabase/server";
import { getAdminSessionFromCookies } from "@/lib/admin-auth";

/** Список / деталь прохождений — только site admin (Auth session). */
export async function GET(request: Request) {
  const email = await getAdminSessionFromCookies();
  if (!email) {
    return NextResponse.json({ error: "unauthorized" }, { status: 401 });
  }

  const { searchParams } = new URL(request.url);
  const id = searchParams.get("id")?.trim();
  const supabase = await createClient();

  if (id) {
    const { data, error } = await supabase.rpc("honest_quiz_admin_get", {
      p_id: id,
    });
    if (error) {
      return NextResponse.json({ error: error.message }, { status: 400 });
    }
    return NextResponse.json({ run: data });
  }

  const { data, error } = await supabase.rpc("honest_quiz_admin_list");
  if (error) {
    return NextResponse.json({ error: error.message }, { status: 400 });
  }
  return NextResponse.json({ runs: Array.isArray(data) ? data : [] });
}
