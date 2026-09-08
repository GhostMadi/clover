import type { Metadata } from "next";
import Link from "next/link";
import { LegalPage, LegalSection } from "@/components/legal-page";
import { SITE } from "@/lib/site";

export const metadata: Metadata = {
  title: "Поддержка",
  description: "Служба поддержки Clover — как связаться и что указать в обращении.",
  alternates: { canonical: "/support" },
};

export default function SupportPage() {
  return (
    <LegalPage title="Поддержка" updated="8 сентября 2026">
      <LegalSection title="Как связаться">
        <p>
          Пишите на{" "}
          <a className="text-brand underline underline-offset-2" href={`mailto:${SITE.email}`}>
            {SITE.email}
          </a>
          . Обычно отвечаем в рабочие дни.
        </p>
        <p>В письме укажите: ник или email аккаунта, устройство (iOS / Android), коротко суть проблемы и шаги, как повторить.</p>
      </LegalSection>

      <LegalSection title="Чем можем помочь">
        <ul className="list-disc space-y-1 pl-5">
          <li>вход, регистрация, сброс пароля;</li>
          <li>запись, посещаемость, публикации и профиль;</li>
          <li>запрос на доступ / исправление / удаление данных аккаунта.</li>
        </ul>
      </LegalSection>

      <LegalSection title="Документы">
        <p>
          <Link className="text-brand underline underline-offset-2" href="/privacy">
            Политика конфиденциальности
          </Link>
          {" · "}
          <Link className="text-brand underline underline-offset-2" href="/privacy-choices">
            Параметры конфиденциальности
          </Link>
          {" · "}
          <Link className="text-brand underline underline-offset-2" href="/terms">
            Условия использования
          </Link>
        </p>
      </LegalSection>

      <LegalSection title="Сайт">
        <p>
          Официальный сайт:{" "}
          <a className="text-brand underline underline-offset-2" href={SITE.url}>
            {SITE.domain}
          </a>
        </p>
      </LegalSection>
    </LegalPage>
  );
}
