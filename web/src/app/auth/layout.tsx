import Image from "next/image";
import Link from "next/link";
import { SITE } from "@/lib/site";

export default function AuthLayout({ children }: { children: React.ReactNode }) {
  return (
    <div className="relative min-h-screen bg-bg-auth text-on-media">
      <div aria-hidden className="auth-atmosphere pointer-events-none absolute inset-0" />
      <div className="relative mx-auto flex min-h-screen w-full max-w-6xl flex-col lg:flex-row">
        <aside className="flex flex-col items-center justify-center gap-4 px-6 pt-12 pb-6 lg:w-[44%] lg:items-start lg:px-12 lg:py-16">
          <Link href="/" className="flex flex-col items-center gap-4 lg:items-start">
            <Image
              src="/logo.png"
              alt={SITE.name}
              width={96}
              height={96}
              priority
              className="h-16 w-16 object-contain sm:h-20 sm:w-20 lg:h-28 lg:w-28"
            />
            <span className="font-display text-3xl font-semibold tracking-tight text-brand-soft sm:text-4xl lg:text-5xl">
              {SITE.name}
            </span>
          </Link>
          <p className="hidden max-w-sm text-sm leading-relaxed text-on-media/50 lg:block">
            Тот же вход, что в приложении — ник или email, пароль, Google.
          </p>
        </aside>

        <section className="flex flex-1 items-start justify-center px-5 pb-12 lg:items-center lg:px-10 lg:py-16">
          <div className="w-full max-w-md">{children}</div>
        </section>
      </div>
    </div>
  );
}
