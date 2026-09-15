import { NextResponse } from "next/server";
import {
  ADMIN_SESSION_COOKIE,
  adminSessionCookieOptions,
  assertAdminSessionSecret,
  createAdminSessionToken,
} from "@/lib/admin-auth";
import { createAdminAuthClient } from "@/lib/supabase/admin-auth-client";

const MIN_PASSWORD = 8;

/** Вход существующим пользователем — только если profiles.is_site_admin. */
export async function POST(request: Request) {
  if (!assertAdminSessionSecret()) {
    return NextResponse.json(
      { error: "Админка не настроена (нет ADMIN_SESSION_SECRET)" },
      { status: 503 },
    );
  }

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

  try {
    const supabase = createAdminAuthClient();
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
      return NextResponse.json({ error: flagError.message }, { status: 500 });
    }
    if (!isAdmin) {
      return NextResponse.json(
        {
          error:
            "Этот аккаунт не отмечен как админ сайта. Нажми «Сделать админом» (один раз, пока админов нет).",
        },
        { status: 403 },
      );
    }

    const token = createAdminSessionToken(email);
    const response = NextResponse.json({ ok: true, userId: data.user.id });
    response.cookies.set(ADMIN_SESSION_COOKIE, token, adminSessionCookieOptions());
    return response;
  } catch (e) {
    return NextResponse.json(
      { error: e instanceof Error ? e.message : "Ошибка входа" },
      { status: 500 },
    );
  }
}
