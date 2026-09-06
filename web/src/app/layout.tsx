import type { Metadata } from "next";
import { Manrope, Sora } from "next/font/google";
import { AppPrefsBootstrap } from "@/features/settings/components/app-prefs-bootstrap";
import { SITE } from "@/lib/site";
import "./globals.css";

/** Анти-FOUC: тема из localStorage до гидрации. */
const THEME_BOOT =
  "(function(){try{var t=localStorage.getItem('clover-web-theme');if(t==='dark')document.documentElement.setAttribute('data-theme','dark');var l=localStorage.getItem('clover-web-locale');if(l==='kk'||l==='en'||l==='ru')document.documentElement.setAttribute('lang',l==='kk'?'kk':l);}catch(e){}})();";

const manrope = Manrope({
  subsets: ["latin", "cyrillic"],
  variable: "--font-manrope",
  display: "swap",
});

const sora = Sora({
  subsets: ["latin"],
  variable: "--font-sora",
  display: "swap",
});

export const metadata: Metadata = {
  metadataBase: new URL(SITE.url),
  title: {
    default: `${SITE.name} — ${SITE.tagline}`,
    template: `%s · ${SITE.name}`,
  },
  description: SITE.description,
  alternates: { canonical: "/" },
  openGraph: {
    title: SITE.name,
    description: SITE.tagline,
    url: SITE.url,
    siteName: SITE.name,
    locale: SITE.locale,
    type: "website",
  },
  robots: { index: true, follow: true },
};

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return (
    // data-theme / lang ставятся скриптом из localStorage до гидрации — как next-themes
    <html
      lang="ru"
      data-scroll-behavior="smooth"
      className={`${manrope.variable} ${sora.variable}`}
      suppressHydrationWarning
    >
      <head>
        <script dangerouslySetInnerHTML={{ __html: THEME_BOOT }} />
      </head>
      <body className="min-h-screen antialiased" suppressHydrationWarning>
        <AppPrefsBootstrap />
        {children}
      </body>
    </html>
  );
}
