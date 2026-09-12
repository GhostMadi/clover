import { NextResponse } from "next/server";
import { createClient } from "@/lib/supabase/server";
import { getAdminSessionFromCookies } from "@/lib/admin-auth";
import { HONEST_QUIZ_ADMIN_SECRET_DEFAULT } from "@/features/honest-quiz/lib/honest-quiz-api";

function adminSecret(): string {
  return process.env.HONEST_QUIZ_ADMIN_SECRET?.trim() || HONEST_QUIZ_ADMIN_SECRET_DEFAULT;
}

export async function GET(request: Request) {
  const email = await getAdminSessionFromCookies();
  if (!email) {
    return NextResponse.json({ error: "unauthorized" }, { status: 401 });
  }

  const { searchParams } = new URL(request.url);
  const id = searchParams.get("id")?.trim();
  const supabase = await createClient();
  const secret = adminSecret();

  if (id) {
    const { data, error } = await supabase.rpc("honest_quiz_admin_get", {
      p_secret: secret,
      p_id: id,
    });
    if (error) {
      return NextResponse.json({ error: error.message }, { status: 400 });
    }
    return NextResponse.json({ run: data });
  }

  const { data, error } = await supabase.rpc("honest_quiz_admin_list", {
    p_secret: secret,
  });
  if (error) {
    return NextResponse.json({ error: error.message }, { status: 400 });
  }
  return NextResponse.json({ runs: Array.isArray(data) ? data : [] });
}
