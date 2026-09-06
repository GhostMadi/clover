import Link from "next/link";
import { SITE } from "@/lib/site";

export function SiteFooter() {
  const year = new Date().getFullYear();

  return (
    <footer className="border-t border-line bg-surface">
      <div className="mx-auto max-w-6xl px-5 pt-12 pb-6 sm:px-8">
        <div className="flex flex-col gap-6 sm:flex-row sm:items-start sm:justify-between">
          <div>
            <p className="font-display text-2xl font-semibold tracking-tight text-ink">{SITE.name}</p>
            <p className="mt-1 text-sm text-muted">{SITE.domain}</p>
            <p className="mt-4 max-w-md text-sm leading-relaxed text-muted">
              Помощник для бизнеса: маркетинг, запись, посещаемость и ресурсы. {SITE.freeNote}.
            </p>
            <Link
              href="/auth"
              className="mt-5 inline-flex h-11 items-center rounded-[14px] bg-brand px-5 text-sm font-semibold text-ink"
            >
              Войти
            </Link>
          </div>
          <a href={`mailto:${SITE.email}`} className="text-sm text-muted transition hover:text-ink">
            {SITE.email}
          </a>
        </div>

        <div className="mt-14 flex flex-col gap-2 border-t border-line pt-5 text-xs text-muted/70 sm:flex-row sm:items-center sm:justify-between">
          <p>
            © {year} {SITE.name}
          </p>
          <div className="flex flex-wrap gap-x-4 gap-y-1">
            <Link href="/privacy" className="hover:text-muted">
              Политика конфиденциальности
            </Link>
            <Link href="/terms" className="hover:text-muted">
              Условия использования
            </Link>
          </div>
        </div>
      </div>
    </footer>
  );
}
