import Link from "next/link";
import { SITE } from "@/lib/site";

const links = [
  { href: "/#services", label: "Сервисы" },
  { href: "/#next", label: "Дальше" },
];

export function SiteHeader() {
  return (
    <header className="sticky top-0 z-40 border-b border-line/70 bg-bg/75 backdrop-blur-xl">
      <div className="mx-auto flex h-[4.25rem] max-w-6xl items-center justify-between gap-3 px-5 sm:px-8">
        <Link href="/" className="group flex min-w-0 items-baseline gap-2">
          <span className="font-display text-[1.35rem] font-semibold tracking-tight text-ink transition group-hover:text-brand">
            {SITE.name}
          </span>
          <span className="hidden truncate text-xs tracking-wide text-muted sm:inline">{SITE.domain}</span>
        </Link>
        <nav className="flex shrink-0 items-center gap-3 sm:gap-5">
          {links.map((link) => (
            <Link
              key={link.href}
              href={link.href}
              className="hidden text-sm text-muted transition hover:text-ink md:inline"
            >
              {link.label}
            </Link>
          ))}
          <Link
            href="/auth"
            className="inline-flex h-10 items-center rounded-[14px] bg-brand px-4 text-sm font-semibold text-ink shadow-elevate-brand transition hover:opacity-90 sm:px-5"
          >
            Войти
          </Link>
        </nav>
      </div>
    </header>
  );
}
