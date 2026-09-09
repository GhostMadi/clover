import { createHash, createHmac, timingSafeEqual } from "node:crypto";
import { cookies } from "next/headers";

export const ADMIN_SESSION_COOKIE = "clover_admin_session";
const SESSION_TTL_SEC = 60 * 60 * 12; // 12h

function requireEnv(name: string): string {
  const value = process.env[name]?.trim();
  if (!value) {
    throw new Error(`Missing env ${name}`);
  }
  return value;
}

function sha256(value: string): Buffer {
  return createHash("sha256").update(value, "utf8").digest();
}

function safeEqualText(a: string, b: string): boolean {
  const left = sha256(a);
  const right = sha256(b);
  return timingSafeEqual(left, right);
}

export function getAdminCredentials(): { email: string; password: string } | null {
  const email = process.env.ADMIN_EMAIL?.trim().toLowerCase();
  const password = process.env.ADMIN_PASSWORD;
  if (!email || !password) return null;
  return { email, password };
}

export function verifyAdminLogin(emailRaw: string, passwordRaw: string): boolean {
  const creds = getAdminCredentials();
  if (!creds) return false;
  const email = emailRaw.trim().toLowerCase();
  const password = passwordRaw;
  return safeEqualText(email, creds.email) && safeEqualText(password, creds.password);
}

function signPayload(payload: string, secret: string): string {
  return createHmac("sha256", secret).update(payload).digest("base64url");
}

export function createAdminSessionToken(email: string): string {
  const secret = requireEnv("ADMIN_SESSION_SECRET");
  const exp = Math.floor(Date.now() / 1000) + SESSION_TTL_SEC;
  const payload = `${email.trim().toLowerCase()}.${exp}`;
  return `${payload}.${signPayload(payload, secret)}`;
}

export function readAdminSessionEmail(token: string | undefined | null): string | null {
  if (!token) return null;
  const secret = process.env.ADMIN_SESSION_SECRET?.trim();
  if (!secret) return null;

  const parts = token.split(".");
  if (parts.length !== 3) return null;
  const [email, expRaw, sig] = parts;
  if (!email || !expRaw || !sig) return null;

  const payload = `${email}.${expRaw}`;
  const expected = signPayload(payload, secret);
  const left = Buffer.from(sig);
  const right = Buffer.from(expected);
  if (left.length !== right.length || !timingSafeEqual(left, right)) return null;

  const exp = Number(expRaw);
  if (!Number.isFinite(exp) || exp < Math.floor(Date.now() / 1000)) return null;

  const creds = getAdminCredentials();
  if (!creds || !safeEqualText(email, creds.email)) return null;
  return email;
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
