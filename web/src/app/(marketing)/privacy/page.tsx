import type { Metadata } from "next";
import Link from "next/link";
import { LegalPage, LegalSection } from "@/components/legal-page";
import { SITE } from "@/lib/site";

export const metadata: Metadata = {
  title: "Политика конфиденциальности",
  description: "Как Clover обрабатывает персональные данные пользователей.",
  alternates: { canonical: "/privacy" },
};

export default function PrivacyPage() {
  return (
    <LegalPage title="Политика конфиденциальности" updated="8 сентября 2026">
      <LegalSection title="1. Кто оператор">
        <p>
          Сервис Clover (приложение и сайт{" "}
          <a className="text-brand underline underline-offset-2" href={SITE.url}>
            {SITE.domain}
          </a>
          ). По вопросам персональных данных:{" "}
          <a className="text-brand underline underline-offset-2" href={`mailto:${SITE.email}`}>
            {SITE.email}
          </a>
          .
        </p>
        <p>
          Практические шаги (разрешения, удаление аккаунта):{" "}
          <Link className="text-brand underline underline-offset-2" href="/privacy-choices">
            параметры конфиденциальности
          </Link>
          .
        </p>
      </LegalSection>

      <LegalSection title="2. Какие данные обрабатываем">
        <p>В зависимости от того, чем вы пользуетесь, мы можем обрабатывать:</p>
        <ul className="list-disc space-y-1 pl-5">
          <li>
            <strong className="font-semibold text-ink">Аккаунт:</strong> email, ник, имя/отображаемое имя, аватар,
            город/страна, телефон — если вы их указали; данные входа (в т.ч. через Google).
          </li>
          <li>
            <strong className="font-semibold text-ink">Контент:</strong> посты, медиа, комментарии, реакции,
            сообщения в чатах, настройки профиля и фильтров.
          </li>
          <li>
            <strong className="font-semibold text-ink">Бизнес-функции:</strong> услуги и записи (запись), данные
            компаний/смен/отметок (посещаемость), местоположения и материалы (ресурсы) — если вы ими пользуетесь.
          </li>
          <li>
            <strong className="font-semibold text-ink">Технические:</strong> идентификаторы устройства и сессии,
            push-токен (для уведомлений), журналы безопасности и диагностики, необходимые для работы сервиса.
          </li>
          <li>
            <strong className="font-semibold text-ink">Геолокация:</strong> только после разрешения системы — для
            карты и геозоны посещаемости (отметки на смене). Мы не требуем геолокацию для обычного просмотра ленты.
          </li>
        </ul>
      </LegalSection>

      <LegalSection title="3. Цели обработки">
        <p>Данные нужны, чтобы:</p>
        <ul className="list-disc space-y-1 pl-5">
          <li>создавать и обслуживать аккаунт, вход и восстановление доступа;</li>
          <li>показывать ленту, карту, профиль, чаты и уведомления;</li>
          <li>обеспечивать запись к услугам и учёт посещаемости;</li>
          <li>обеспечивать безопасность, предотвращать злоупотребления и устранять сбои;</li>
          <li>отвечать на обращения в поддержку.</li>
        </ul>
        <p>
          Мы <strong className="font-semibold text-ink">не продаём</strong> персональные данные третьим лицам и не
          передаём их рекламным сетям для показа сторонней рекламы от имени Clover.
        </p>
      </LegalSection>

      <LegalSection title="4. Камера, фото, геолокация, уведомления">
        <p>
          Доступ к камере, галерее, геолокации и уведомлениям запрашивается системой устройства и используется
          только для соответствующих функций (медиа для постов/профиля, карта, геозона смен, push). Вы можете
          отозвать разрешения в настройках телефона — см.{" "}
          <Link className="text-brand underline underline-offset-2" href="/privacy-choices">
            параметры конфиденциальности
          </Link>
          .
        </p>
      </LegalSection>

      <LegalSection title="5. Передача и инфраструктура">
        <p>
          Для работы сервиса мы используем провайдеров инфраструктуры (облачная база данных и хранилище файлов,
          доставка push, карты, вход через Google). Они обрабатывают данные по нашим поручениям / в рамках своих
          политик как необходимые для предоставления функций. Мы не передаём данные «на продажу».
        </p>
      </LegalSection>

      <LegalSection title="6. Срок хранения">
        <p>
          Данные хранятся, пока нужен ваш аккаунт и сервис. После удаления аккаунта персональные данные удаляются
          или обезличиваются в разумный срок, кроме случаев, когда закон или безопасность требуют иное (например,
          расследование злоупотреблений).
        </p>
      </LegalSection>

      <LegalSection title="7. Ваши права">
        <p>
          Вы можете запросить доступ, исправление или удаление данных, связанных с аккаунтом, через приложение
          (где доступно) или по email{" "}
          <a className="text-brand underline underline-offset-2" href={`mailto:${SITE.email}`}>
            {SITE.email}
          </a>
          . Подробные шаги — на странице{" "}
          <Link className="text-brand underline underline-offset-2" href="/privacy-choices">
            параметров конфиденциальности
          </Link>
          . Мы ответим в разумный срок.
        </p>
      </LegalSection>

      <LegalSection title="8. Дети">
        <p>
          Сервис не предназначен для детей младше 13 лет. Если вам нет 13 лет, не создавайте аккаунт без согласия
          законного представителя.
        </p>
      </LegalSection>

      <LegalSection title="9. Изменения">
        <p>
          Мы можем обновлять эту политику. Актуальная версия всегда на этой странице; дата обновления указана
          сверху.
        </p>
      </LegalSection>

      <LegalSection title="10. Контакты">
        <p>
          Данные и поддержка:{" "}
          <a className="text-brand underline underline-offset-2" href={`mailto:${SITE.email}`}>
            {SITE.email}
          </a>{" "}
          ·{" "}
          <Link className="text-brand underline underline-offset-2" href="/support">
            страница поддержки
          </Link>
        </p>
      </LegalSection>
    </LegalPage>
  );
}
