import { NextResponse } from "next/server";
import { createServerClient } from "@supabase/ssr";
import { cookies } from "next/headers";
import { supabaseCookieOptions } from "@/lib/supabase/cookie-options";

const MIN_PASSWORD = 8;

/**
 * Вход email+пароль аккаунта Clover.
 * Пускает только если profiles.is_site_admin.
 * Сессия — обычные Supabase Auth cookies (без ADMIN_SESSION_SECRET).
 */
export async function POST(request: Request) {
  let body: { email?: string; password?: string };
  try {
    body = (await request.json()) as { email?: string; password?: string };
  } catch {
    return NextResponse.json({ error: "Некорректный запрос" }, { status: 400 });
  }

  const email = typeof body.email === "string" ? body.email.trim().toLowerCase() : "";
  const password = typeof body.password === "string" ? body.password : "";

  if (!email.includes("@") || password.length < MIN_PASSWORD) {
    return NextResponse.json(
      { error: `Укажите email и пароль от ${MIN_PASSWORD} символов` },
      { status: 400 },
    );
  }

  const url = process.env.NEXT_PUBLIC_SUPABASE_URL?.trim();
  const anon = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY?.trim();
  if (!url || !anon) {
    return NextResponse.json({ error: "Нет конфигурации Supabase" }, { status: 500 });
  }

  try {
    const cookieStore = await cookies();
    const supabase = createServerClient(url, anon, {
      cookieOptions: supabaseCookieOptions,
      cookies: {
        getAll() {
          return cookieStore.getAll();
        },
        setAll(cookiesToSet) {
          cookiesToSet.forEach(({ name, value, options }) => {
            cookieStore.set(name, value, { ...supabaseCookieOptions, ...options });
          });
        },
      },
      auth: {
        flowType: "pkce",
        detectSessionInUrl: false,
        persistSession: true,
        autoRefreshToken: true,
      },
    });

    const { data, error } = await supabase.auth.signInWithPassword({ email, password });
    if (error || !data.user) {
      const code = (error as { code?: string } | null)?.code ?? "";
      const msg = (error?.message ?? "").toLowerCase();
      if (code === "email_not_confirmed" || msg.includes("email not confirmed")) {
        return NextResponse.json(
          { error: "Email не подтверждён в Auth. Подтверди в Dashboard → Users." },
          { status: 401 },
        );
      }
      return NextResponse.json({ error: "Неверный email или пароль" }, { status: 401 });
    }

    const { data: isAdmin, error: flagError } = await supabase.rpc("is_site_admin");
    if (flagError) {
      await supabase.auth.signOut();
      return NextResponse.json({ error: flagError.message }, { status: 500 });
    }
    if (!isAdmin) {
      await supabase.auth.signOut();
      return NextResponse.json(
        {
          error:
            "Этот аккаунт не админ сайта. В SQL: update profiles set is_site_admin = true where email = '…'",
        },
        { status: 403 },
      );
    }

    return NextResponse.json({ ok: true, userId: data.user.id });
  } catch (e) {
    return NextResponse.json(
      { error: e instanceof Error ? e.message : "Ошибка входа" },
      { status: 500 },
    );
  }
}
