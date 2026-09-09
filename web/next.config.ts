import type { NextConfig } from "next";

/**
 * Базовые security headers.
 * Полностью «спрятать» JWT в DevTools Network нельзя — браузер всегда видит свои запросы.
 * Защита: RLS + публичный только anon key + Secure cookies + эти заголовки.
 */
const securityHeaders = [
  { key: "X-Content-Type-Options", value: "nosniff" },
  { key: "X-Frame-Options", value: "DENY" },
  { key: "Referrer-Policy", value: "strict-origin-when-cross-origin" },
  {
    key: "Permissions-Policy",
    value: "camera=(), microphone=(), geolocation=(self), payment=()",
  },
  {
    key: "Strict-Transport-Security",
    value: "max-age=63072000; includeSubDomains; preload",
  },
];

const nextConfig: NextConfig = {
  poweredByHeader: false,
  async headers() {
    return [
      {
        source: "/:path*",
        headers: securityHeaders,
      },
    ];
  },
  async rewrites() {
    // Same-origin media proxy → R2 Custom Domain (see web/src/lib/media-url.ts).
    return [
      {
        source: "/media/:path*",
        destination: "https://media.clover.com.kz/:path*",
      },
    ];
  },
};

export default nextConfig;
