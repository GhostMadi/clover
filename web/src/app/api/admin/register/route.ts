import { NextResponse } from "next/server";
import {
  ADMIN_SESSION_COOKIE,
  adminSessionCookieOptions,
  assertAdminSessionSecret,
  createAdminSessionToken,
  isAdminRegisterAllowed,
} from "@/lib/admin-auth";
import { createAdminAuthClient } from "@/lib/supabase/admin-auth-client";

const MIN_PASSWORD = 8;

/**
 * Существующий пользователь → profiles.is_site_admin = true (только если админов ещё нет).
 * Новый Auth-аккаунт не создаём.
 */
export async function POST(request: Request) {
  if (!isAdminRegisterAllowed()) {
    return NextResponse.json(
      { error: "Назначение админа выключено (ADMIN_ALLOW_REGISTER=0)" },
      { status: 403 },
    );
  }

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
          { error: "Email не подтверждён. Подтверди в Dashboard → Authentication → Users." },
          { status: 401 },
        );
      }
      return NextResponse.json(
        { error: "Неверный email или пароль обычного аккаунта Clover" },
        { status: 401 },
      );
    }

    const { error: promoteError } = await supabase.rpc("promote_self_to_site_admin");
    if (promoteError) {
      const msg = promoteError.message.toLowerCase();
      if (msg.includes("site_admin_exists")) {
        return NextResponse.json(
          {
            error:
              "Админ сайта уже назначен. Войди тем аккаунтом или сбрось флаг в SQL: profiles.is_site_admin.",
          },
          { status: 409 },
        );
      }
      if (msg.includes("profile_missing")) {
        return NextResponse.json(
          { error: "Профиль не найден. Сначала зайди в кабинет /app хотя бы раз." },
          { status: 400 },
        );
      }
      return NextResponse.json({ error: promoteError.message }, { status: 400 });
    }

    const token = createAdminSessionToken(email);
    const response = NextResponse.json({ ok: true, userId: data.user.id });
    response.cookies.set(ADMIN_SESSION_COOKIE, token, adminSessionCookieOptions());
    return response;
  } catch (e) {
    return NextResponse.json(
      { error: e instanceof Error ? e.message : "Ошибка назначения" },
      { status: 500 },
    );
  }
}
