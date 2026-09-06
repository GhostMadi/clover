import type { Metadata } from "next";
import { LegalPage, LegalSection } from "@/components/legal-page";
import { SITE } from "@/lib/site";

export const metadata: Metadata = {
  title: "Условия использования",
  description: "Правила использования приложения и сайта Clover.",
  alternates: { canonical: "/terms" },
};

export default function TermsPage() {
  return (
    <LegalPage title="Условия использования" updated="6 сентября 2026">
      <LegalSection title="1. Принятие условий">
        <p>
          Используя приложение или сайт {SITE.domain}, вы соглашаетесь с этими условиями и{" "}
          <a className="text-brand underline underline-offset-2" href="/privacy">
            политикой конфиденциальности
          </a>
          .
        </p>
      </LegalSection>

      <LegalSection title="2. Сервис">
        <p>
          Clover предоставляет функции публикаций, карты событий, социальных взаимодействий, записи к услугам и
          посещаемости. Набор функций может отличаться по ролям и со временем дополняться (в том числе веб-кабинет).
        </p>
      </LegalSection>

      <LegalSection title="3. Аккаунт">
        <p>
          Вы отвечаете за сохранность доступа к аккаунту и за действия, совершённые под ним. Указывайте достоверные
          данные при регистрации и в профиле.
        </p>
      </LegalSection>

      <LegalSection title="4. Контент пользователей">
        <p>
          Вы сохраняете права на свой контент и даёте Clover лицензию на его показ в рамках сервиса. Запрещены
          незаконный контент, спам, вредоносные действия и нарушение прав других людей.
        </p>
      </LegalSection>

      <LegalSection title="5. Бизнес-функции">
        <p>
          Запись, посещаемость и связанные настройки используются на ваш риск как инструменты организации работы.
          Юридические и трудовые обязательства между работодателем и сотрудником остаются между ними.
        </p>
      </LegalSection>

      <LegalSection title="6. Ограничение ответственности">
        <p>
          Сервис предоставляется «как есть». Мы стремимся к стабильной работе, но не гарантируем отсутствие сбоев.
          В пределах, допускаемых законом, ответственность ограничена.
        </p>
      </LegalSection>

      <LegalSection title="7. Прекращение">
        <p>
          Вы можете перестать пользоваться сервисом и запросить удаление аккаунта. Мы можем ограничить доступ при
          нарушении условий или требований закона.
        </p>
      </LegalSection>

      <LegalSection title="8. Контакты">
        <p>
          Вопросы по условиям:{" "}
          <a className="text-brand underline underline-offset-2" href={`mailto:${SITE.email}`}>
            {SITE.email}
          </a>
          .
        </p>
      </LegalSection>
    </LegalPage>
  );
}
