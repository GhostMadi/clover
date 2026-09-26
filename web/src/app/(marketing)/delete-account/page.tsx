import type { Metadata } from "next";
import Link from "next/link";
import { LegalPage, LegalSection } from "@/components/legal-page";
import { SITE } from "@/lib/site";

export const metadata: Metadata = {
  title: "Удаление аккаунта",
  description:
    "Как деактивировать аккаунт Clover в приложении и как запросить безвозвратное удаление данных.",
  alternates: { canonical: "/delete-account" },
};

export default function DeleteAccountPage() {
  return (
    <LegalPage title="Удаление аккаунта Clover" updated="26 сентября 2026">
      <LegalSection title="О сервисе">
        <p>
          Эта страница относится к приложению и сайту{" "}
          <strong className="font-semibold text-ink">{SITE.name}</strong> ({SITE.domain}). Здесь —
          два разных действия: деактивация в приложении и безвозвратное удаление данных через
          поддержку.
        </p>
      </LegalSection>

      <LegalSection title="1. Деактивировать в приложении или на сайте (мгновенно)">
        <p>
          Это скрытие профиля, а не безвозвратное стирание данных. Подходит, если хотите временно
          уйти из лент.
        </p>
        <ol className="mt-2 list-decimal space-y-2 pl-5">
          <li>Войдите в аккаунт {SITE.name} (мобильное приложение или веб).</li>
          <li>
            Откройте <strong className="font-semibold text-ink">Настройки → Аккаунт</strong>.
          </li>
          <li>
            Нажмите <strong className="font-semibold text-ink">«Деактивировать аккаунт»</strong> и
            подтвердите. Профиль и публикации скрываются из лент (как при «уснуть»). При следующем
            входе аккаунт снова активен.
          </li>
        </ol>
      </LegalSection>

      <LegalSection title="2. Безвозвратное удаление данных (через поддержку)">
        <p>
          Чтобы навсегда удалить аккаунт и связанные данные (требование магазинов приложений и
          политик конфиденциальности), отправьте запрос в поддержку. Мы подтверждаем владельца и
          выполняем удаление или обезличивание.
        </p>
        <ol className="mt-2 list-decimal space-y-2 pl-5">
          <li>
            Откройте{" "}
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
            В тексте напишите:{" "}
            <strong className="font-semibold text-ink">«Безвозвратное удаление аккаунта»</strong> и
            коротко подтвердите, что это ваш аккаунт.
          </li>
          <li>
            Отправьте форму. Стремимся завершить в течение{" "}
            <strong className="font-semibold text-ink">30 дней</strong> после понятного запроса.
          </li>
        </ol>
      </LegalSection>

      <LegalSection title="Что удаляется при безвозвратном запросе">
        <p>После подтверждения запроса мы удаляем или обезличиваем данные аккаунта, в том числе:</p>
        <ul className="list-disc space-y-1 pl-5">
          <li>данные профиля (имя, ник, аватар, контактные поля профиля);</li>
          <li>
            контент, привязанный к аккаунту (посты, медиа, сообщения — в объёме, доступном к
            удалению);
          </li>
          <li>технические привязки входа (сессии, push-токены устройства).</li>
        </ul>
      </LegalSection>

      <LegalSection title="Что может быть сохранено">
        <p>
          Отдельные сведения могут остаться на ограниченный срок, если этого требуют закон,
          безопасность или разбор злоупотреблений (например, журналы безопасности). Такие данные не
          используются для обычной работы сервиса после удаления аккаунта и удаляются или
          обезличиваются, когда основание отпадает.
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
