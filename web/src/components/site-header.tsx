import Image from "next/image";
import Link from "next/link";
import { SITE } from "@/lib/site";
import { ThemeToggle } from "@/components/theme-toggle";

export function SiteHeader() {
  return (
    <header className="sticky top-0 z-40 border-b border-line/70 bg-bg/80 backdrop-blur-xl">
      <div className="mx-auto flex h-[4.25rem] max-w-3xl items-center justify-between gap-3 px-5 sm:px-8">
        <Link href="/" className="group flex min-w-0 items-center gap-2.5">
          <Image
            src="/logo.png"
            alt=""
            width={32}
            height={32}
            className="h-8 w-8 object-contain"
          />
          <span className="font-display text-[1.35rem] font-semibold tracking-tight text-ink transition group-hover:text-brand">
            {SITE.name}
          </span>
        </Link>
        <div className="flex shrink-0 items-center gap-2.5">
          <ThemeToggle />
          <Link
            href="/auth"
            className="inline-flex h-10 items-center rounded-[14px] bg-brand px-4 text-sm font-semibold text-ink shadow-elevate-brand transition hover:opacity-90 sm:px-5"
          >
            Войти
          </Link>
        </div>
      </div>
    </header>
  );
}
