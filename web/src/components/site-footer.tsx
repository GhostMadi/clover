import Link from "next/link";
import { SITE } from "@/lib/site";

export function SiteFooter() {
  const year = new Date().getFullYear();

  return (
    <footer className="border-t border-line bg-surface">
      <div className="mx-auto flex max-w-3xl flex-col gap-3 px-5 py-6 sm:flex-row sm:items-center sm:justify-between sm:px-8">
        <p className="text-[12px] text-muted">
          © {year} {SITE.name}
        </p>
        <div className="flex flex-wrap gap-x-4 gap-y-1 text-[12px] text-muted">
          <Link href={SITE.supportPath} className="hover:text-ink">
            Поддержка
          </Link>
          <Link href="/delete-account" className="hover:text-ink">
            Удаление аккаунта
          </Link>
          <Link href="/privacy" className="hover:text-ink">
            Конфиденциальность
          </Link>
          <Link href="/privacy-choices" className="hover:text-ink">
            Параметры данных
          </Link>
          <Link href="/terms" className="hover:text-ink">
            Условия
          </Link>
        </div>
      </div>
    </footer>
  );
}
