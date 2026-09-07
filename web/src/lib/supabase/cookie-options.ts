/** Общие опции auth-cookie для @supabase/ssr (не localStorage). */
export const supabaseCookieOptions = {
  path: "/",
  sameSite: "lax" as const,
  /** На проде только HTTPS. На localhost Secure ломает cookie. */
  secure: process.env.NODE_ENV === "production",
  maxAge: 60 * 60 * 24 * 400,
};
