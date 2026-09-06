"use client";

import { createClient } from "@/lib/supabase/client";
import { AUTH_MESSAGES, MIN_PASSWORD_LENGTH } from "@/features/auth/lib/messages";

function normalizeEmail(email: string) {
  return email.trim().toLowerCase();
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

  const supabase = createClient();
  const { error } = await supabase.auth.signInWithOtp({
    email: trimmed,
    options: { shouldCreateUser: true },
  });
  if (error) throw new Error(AUTH_MESSAGES.generic);
}

export async function sendForgotOtp(email: string) {
  const trimmed = normalizeEmail(email);
  if (!trimmed.includes("@")) throw new Error(AUTH_MESSAGES.emailInvalid);
  if (!(await isEmailRegistered(trimmed))) {
    throw new Error(AUTH_MESSAGES.emailNotRegistered);
  }

  const supabase = createClient();
  const { error } = await supabase.auth.signInWithOtp({
    email: trimmed,
    options: { shouldCreateUser: false },
  });
  if (error) throw new Error(AUTH_MESSAGES.generic);
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
  const { error } = await supabase.auth.updateUser({ password: password.trim() });
  if (error) throw new Error(AUTH_MESSAGES.generic);
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
