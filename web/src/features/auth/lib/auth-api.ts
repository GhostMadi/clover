"use client";

import { createClient } from "@/lib/supabase/client";
import { AUTH_MESSAGES, MIN_PASSWORD_LENGTH } from "@/features/auth/lib/messages";

/** Same as Flutter `AuthRepository.otpMaxPerHour`. */
export const OTP_MAX_PER_HOUR = 3;

function normalizeEmail(email: string) {
  return email.trim().toLowerCase();
}

export class AuthOtpRateLimitError extends Error {
  readonly retryAfterSeconds: number;
  constructor(retryAfterSeconds: number) {
    super(AUTH_MESSAGES.otpRateLimited(retryAfterSeconds));
    this.name = "AuthOtpRateLimitError";
    this.retryAfterSeconds = Math.max(0, Math.ceil(retryAfterSeconds));
  }
}

function isAuthRateLimitMessage(message: string): boolean {
  const m = message.toLowerCase();
  return (
    m.includes("rate limit") ||
    m.includes("over_email_send_rate_limit") ||
    m.includes("too many otp") ||
    m.includes("retry in")
  );
}

/** Parses `Retry in 123 seconds` from Send Email Hook / Auth. */
export function parseRetryAfterSeconds(message: string): number | null {
  const match = /retry in\s+(\d+)\s*seconds?/i.exec(message);
  if (!match) return null;
  const n = Number(match[1]);
  return Number.isFinite(n) && n > 0 ? n : null;
}

/** Soft UX peek; Auth Send Email Hook records the real send (service_role). */
export async function emailOtpRetryAfterSeconds(email: string): Promise<number> {
  const trimmed = normalizeEmail(email);
  if (!trimmed.includes("@")) return 0;
  const supabase = createClient();
  try {
    const { data, error } = await supabase.rpc("auth_email_otp_retry_after", {
      p_email: trimmed,
      p_max_per_hour: OTP_MAX_PER_HOUR,
    });
    if (error) throw error;
    const wait = typeof data === "number" ? data : Number(data) || 0;
    return wait > 0 ? wait : 0;
  } catch {
    return 0;
  }
}

async function assertEmailOtpAllowed(email: string): Promise<void> {
  const wait = await emailOtpRetryAfterSeconds(email);
  if (wait > 0) throw new AuthOtpRateLimitError(wait);
}

async function throwRateLimitForEmail(email: string, fallbackMessage?: string): Promise<never> {
  const fromMsg = fallbackMessage ? parseRetryAfterSeconds(fallbackMessage) : null;
  const wait = await emailOtpRetryAfterSeconds(email);
  throw new AuthOtpRateLimitError(wait > 0 ? wait : fromMsg ?? 0);
}

export async function resolveLoginEmail(identifier: string): Promise<string | null> {
  const raw = identifier.trim();
  if (!raw) throw new Error(AUTH_MESSAGES.identifierInvalid);

  const supabase = createClient();
  try {
    const { data, error } = await supabase.rpc("auth_resolve_login_email", {
      p_identifier: raw,
    });
    if (error) throw error;
    const email = String(data ?? "").trim().toLowerCase();
    if (email) return email;
    if (raw.includes("@")) return raw.toLowerCase();
    return null;
  } catch {
    if (raw.includes("@")) return raw.toLowerCase();
    throw new Error(AUTH_MESSAGES.invalidCredentials);
  }
}

export async function loginWithPassword(identifier: string, password: string) {
  const email = await resolveLoginEmail(identifier);
  if (!email) throw new Error(AUTH_MESSAGES.invalidCredentials);
  const trimmedPassword = password.trim();
  if (!trimmedPassword) throw new Error(AUTH_MESSAGES.invalidCredentials);

  const supabase = createClient();
  const { error } = await supabase.auth.signInWithPassword({
    email,
    password: trimmedPassword,
  });
  if (error) throw new Error(AUTH_MESSAGES.invalidCredentials);

  // Legacy password accounts: stamp metadata (parity with Flutter).
  try {
    const {
      data: { user },
    } = await supabase.auth.getUser();
    const meta = (user?.user_metadata ?? {}) as Record<string, unknown>;
    if (user && meta.clover_password_set !== true) {
      await supabase.auth.updateUser({ data: { clover_password_set: true } });
    }
  } catch {
    // ignore stamp failures
  }

  await reportAccountLogin();
}

export async function isEmailFullyRegistered(email: string) {
  const trimmed = normalizeEmail(email);
  const supabase = createClient();
  const { data, error } = await supabase.rpc("auth_is_email_fully_registered", {
    p_email: trimmed,
  });
  if (error) throw new Error(AUTH_MESSAGES.generic);
  return data === true;
}

export async function isEmailRegistered(email: string) {
  const trimmed = normalizeEmail(email);
  const supabase = createClient();
  const { data, error } = await supabase.rpc("auth_is_email_registered", {
    p_email: trimmed,
  });
  if (error) throw new Error(AUTH_MESSAGES.generic);
  return data === true;
}

export async function sendRegisterOtp(email: string) {
  const trimmed = normalizeEmail(email);
  if (!trimmed.includes("@")) throw new Error(AUTH_MESSAGES.emailInvalid);
  if (await isEmailFullyRegistered(trimmed)) {
    throw new Error(AUTH_MESSAGES.emailAlreadyRegistered);
  }

  await assertEmailOtpAllowed(trimmed);

  const supabase = createClient();
  const { error } = await supabase.auth.signInWithOtp({
    email: trimmed,
    options: { shouldCreateUser: true },
  });
  if (error) {
    if (isAuthRateLimitMessage(error.message)) {
      await throwRateLimitForEmail(trimmed, error.message);
    }
    throw new Error(AUTH_MESSAGES.generic);
  }
}

export async function sendForgotOtp(email: string) {
  const trimmed = normalizeEmail(email);
  if (!trimmed.includes("@")) throw new Error(AUTH_MESSAGES.emailInvalid);
  if (!(await isEmailRegistered(trimmed))) {
    throw new Error(AUTH_MESSAGES.emailNotRegistered);
  }

  await assertEmailOtpAllowed(trimmed);

  const supabase = createClient();
  const { error } = await supabase.auth.signInWithOtp({
    email: trimmed,
    options: { shouldCreateUser: false },
  });
  if (error) {
    if (isAuthRateLimitMessage(error.message)) {
      await throwRateLimitForEmail(trimmed, error.message);
    }
    throw new Error(AUTH_MESSAGES.generic);
  }
}

export async function verifyEmailOtp(email: string, token: string) {
  const supabase = createClient();
  const { error } = await supabase.auth.verifyOtp({
    email: normalizeEmail(email),
    token: token.trim(),
    type: "email",
  });
  if (error) throw new Error(AUTH_MESSAGES.otpInvalid);
}

export async function updatePassword(password: string) {
  if (password.trim().length < MIN_PASSWORD_LENGTH) {
    throw new Error(AUTH_MESSAGES.passwordTooShort);
  }
  const supabase = createClient();
  const { error } = await supabase.auth.updateUser({
    password: password.trim(),
    data: { clover_password_set: true },
  });
  if (error) throw new Error(AUTH_MESSAGES.generic);
  await reportAccountLogin();
}

function sessionIdFromAccessToken(token: string | undefined | null): string | null {
  if (!token) return null;
  const parts = token.split(".");
  if (parts.length < 2) return null;
  try {
    const json = atob(parts[1].replace(/-/g, "+").replace(/_/g, "/"));
    const map = JSON.parse(json) as { session_id?: string };
    const id = map.session_id?.trim();
    return id || null;
  } catch {
    return null;
  }
}

/** After successful sign-in / OAuth callback / password set. */
export async function reportAccountLogin(): Promise<void> {
  try {
    const supabase = createClient();
    const ua = typeof navigator !== "undefined" ? navigator.userAgent : "";
    let deviceLabel: string | null = null;
    if (/iPhone|iPad/i.test(ua)) deviceLabel = "iPhone / iPad";
    else if (/Android/i.test(ua)) deviceLabel = "Android";
    else if (/Mac/i.test(ua)) deviceLabel = "Mac";
    else if (/Windows/i.test(ua)) deviceLabel = "Windows";
    else if (/Linux/i.test(ua)) deviceLabel = "Linux";

    const {
      data: { session },
    } = await supabase.auth.getSession();

    await supabase.rpc("report_account_login", {
      p_client: "web",
      p_platform: "web",
      p_device_label: deviceLabel,
      p_session_id: sessionIdFromAccessToken(session?.access_token),
    });
  } catch {
    // ignore — session already established
  }
}

export async function signInWithGoogle() {
  const supabase = createClient();
  const origin = window.location.origin;
  const { error } = await supabase.auth.signInWithOAuth({
    provider: "google",
    options: {
      redirectTo: `${origin}/auth/callback`,
      queryParams: { access_type: "offline", prompt: "consent" },
    },
  });
  if (error) throw new Error(AUTH_MESSAGES.googleFailed);
}

export async function signOut() {
  const supabase = createClient();
  await supabase.auth.signOut();
}
