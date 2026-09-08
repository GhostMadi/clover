import type { Metadata } from "next";
import Link from "next/link";
import { LegalPage, LegalSection } from "@/components/legal-page";
import { SITE } from "@/lib/site";

export const metadata: Metadata = {
  title: "Удаление аккаунта",
  description: "Как запросить удаление аккаунта Clover и связанных данных.",
  alternates: { canonical: "/delete-account" },
};

export default function DeleteAccountPage() {
  return (
    <LegalPage title="Удаление аккаунта Clover" updated="8 сентября 2026">
      <LegalSection title="О сервисе">
        <p>
          Эта страница относится к приложению и сайту{" "}
          <strong className="font-semibold text-ink">{SITE.name}</strong> ({SITE.domain}). Здесь — как запросить
          удаление аккаунта и связанных с ним данных.
        </p>
      </LegalSection>

      <LegalSection title="Как запросить удаление аккаунта">
        <ol className="list-decimal space-y-2 pl-5">
          <li>
            Откройте страницу поддержки:{" "}
            <Link className="text-brand underline underline-offset-2" href={SITE.supportPath}>
              {SITE.domain}
              {SITE.supportPath}
            </Link>
            .
          </li>
          <li>
            В поле контакта укажите ник или email аккаунта {SITE.name}, который нужно удалить.
          </li>
          <li>
            В тексте обращения напишите: <strong className="font-semibold text-ink">«Удаление аккаунта»</strong> и
            коротко подтвердите, что это ваш аккаунт.
          </li>
          <li>Отправьте форму. Мы обработаем запрос в разумный срок (обычно до 30 дней).</li>
        </ol>
      </LegalSection>

      <LegalSection title="Что будет удалено">
        <p>После подтверждения запроса мы удаляем или обезличиваем данные аккаунта, в том числе:</p>
        <ul className="list-disc space-y-1 pl-5">
          <li>данные профиля (имя, ник, аватар, контактные поля профиля);</li>
          <li>контент, привязанный к аккаунту (посты, медиа, сообщения — в объёме, доступном к удалению);</li>
          <li>технические привязки входа (сессии, push-токены устройства).</li>
        </ul>
      </LegalSection>

      <LegalSection title="Что может быть сохранено">
        <p>
          Отдельные сведения могут остаться на ограниченный срок, если этого требуют закон, безопасность или
          разбор злоупотреблений (например, журналы безопасности). Такие данные не используются для обычной
          работы сервиса после удаления аккаунта и удаляются или обезличиваются, когда основание отпадает.
        </p>
      </LegalSection>

      <LegalSection title="Срок">
        <p>
          Стремимся завершить удаление в разумный срок, как правило в течение <strong className="font-semibold text-ink">30 дней</strong>{" "}
          после получения понятного запроса. Подтверждение может потребоваться, если контакт не совпадает с
          аккаунтом.
        </p>
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
          <Link className="text-brand underline underline-offset-2" href={SITE.supportPath}>
            Поддержка
          </Link>
        </p>
      </LegalSection>
    </LegalPage>
  );
}
