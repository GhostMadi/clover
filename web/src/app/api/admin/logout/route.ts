import { NextResponse } from "next/server";
import { createClient } from "@/lib/supabase/server";

/** Выход из админки = выход из Supabase-сессии этого браузера. */
export async function POST() {
  try {
    const supabase = await createClient();
    await supabase.auth.signOut();
  } catch {
    // ignore
  }
  return NextResponse.json({ ok: true });
}
