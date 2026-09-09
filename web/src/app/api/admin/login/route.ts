import { NextResponse } from "next/server";
import {
  ADMIN_SESSION_COOKIE,
  adminSessionCookieOptions,
  createAdminSessionToken,
  getAdminCredentials,
  verifyAdminLogin,
} from "@/lib/admin-auth";

export async function POST(request: Request) {
  if (!getAdminCredentials() || !process.env.ADMIN_SESSION_SECRET?.trim()) {
    return NextResponse.json(
      { error: "Админка не настроена (нет ADMIN_* env)" },
      { status: 503 },
    );
  }

  let body: { email?: string; password?: string };
  try {
    body = (await request.json()) as { email?: string; password?: string };
  } catch {
    return NextResponse.json({ error: "Некорректный запрос" }, { status: 400 });
  }

  const email = typeof body.email === "string" ? body.email : "";
  const password = typeof body.password === "string" ? body.password : "";

  if (!verifyAdminLogin(email, password)) {
    return NextResponse.json({ error: "Неверный email или пароль" }, { status: 401 });
  }

  const token = createAdminSessionToken(email);
  const response = NextResponse.json({ ok: true });
  response.cookies.set(ADMIN_SESSION_COOKIE, token, adminSessionCookieOptions());
  return response;
}
