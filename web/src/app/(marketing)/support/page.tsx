import type { Metadata } from "next";
import Link from "next/link";
import { LegalPage, LegalSection } from "@/components/legal-page";
import { SupportRequestForm } from "@/features/support/components/support-request-form";
import { SITE } from "@/lib/site";

export const metadata: Metadata = {
  title: "Поддержка",
  description: "Служба поддержки Clover — напишите о проблеме на сайте.",
  alternates: { canonical: "/support" },
};

export default function SupportPage() {
  return (
    <LegalPage title="Поддержка" updated="8 сентября 2026">
      <LegalSection title="Напишите нам">
        <p>
          Опишите проблему в форме ниже. Мы получим заявку в системе и ответим на указанный контакт. Отдельного
          почтового ящика поддержки нет — всё через эту страницу.
        </p>
        <div className="mt-5">
          <SupportRequestForm />
        </div>
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
