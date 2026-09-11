import { createHmac, timingSafeEqual } from "node:crypto";
import { cookies } from "next/headers";

export const ADMIN_SESSION_COOKIE = "clover_admin_session";
const SESSION_TTL_SEC = 60 * 60 * 12; // 12h

/** Назначение админа через UI выключено; флаг только SQL / ручной promote. */
export function isAdminRegisterAllowed(): boolean {
  return false;
}

function requireEnv(name: string): string {
  const value = process.env[name]?.trim();
  if (!value) {
    throw new Error(`Missing env ${name}`);
  }
  return value;
}

function signPayload(payload: string, secret: string): string {
  return createHmac("sha256", secret).update(payload).digest("base64url");
}

/** Payload без `.` в email: base64url(JSON) + подпись (email с точками больше не ломает split). */
export function createAdminSessionToken(email: string): string {
  const secret = requireEnv("ADMIN_SESSION_SECRET");
  const exp = Math.floor(Date.now() / 1000) + SESSION_TTL_SEC;
  const payload = Buffer.from(
    JSON.stringify({ e: email.trim().toLowerCase(), exp }),
    "utf8",
  ).toString("base64url");
  return `${payload}.${signPayload(payload, secret)}`;
}

export function readAdminSessionEmail(token: string | undefined | null): string | null {
  if (!token) return null;
  const secret = process.env.ADMIN_SESSION_SECRET?.trim();
  if (!secret) return null;

  const dot = token.lastIndexOf(".");
  if (dot <= 0 || dot === token.length - 1) return null;
  const payload = token.slice(0, dot);
  const sig = token.slice(dot + 1);

  const expected = signPayload(payload, secret);
  const left = Buffer.from(sig);
  const right = Buffer.from(expected);
  if (left.length !== right.length || !timingSafeEqual(left, right)) return null;

  try {
    const parsed = JSON.parse(Buffer.from(payload, "base64url").toString("utf8")) as {
      e?: unknown;
      exp?: unknown;
    };
    const email = typeof parsed.e === "string" ? parsed.e.trim().toLowerCase() : "";
    const exp = typeof parsed.exp === "number" ? parsed.exp : Number(parsed.exp);
    if (!email.includes("@") || !Number.isFinite(exp)) return null;
    if (exp < Math.floor(Date.now() / 1000)) return null;
    return email;
  } catch {
    return null;
  }
}

export function adminSessionCookieOptions(maxAge = SESSION_TTL_SEC) {
  return {
    httpOnly: true,
    secure: process.env.NODE_ENV === "production",
    sameSite: "lax" as const,
    path: "/",
    maxAge,
  };
}

export async function getAdminSessionFromCookies(): Promise<string | null> {
  const jar = await cookies();
  return readAdminSessionEmail(jar.get(ADMIN_SESSION_COOKIE)?.value);
}

export function assertAdminSessionSecret(): boolean {
  return Boolean(process.env.ADMIN_SESSION_SECRET?.trim());
}
