import type { Metadata } from "next";
import Link from "next/link";
import { LegalPage, LegalSection } from "@/components/legal-page";
import { SITE } from "@/lib/site";

export const metadata: Metadata = {
  title: "Параметры конфиденциальности",
  description:
    "Как в Clover управлять данными, разрешениями устройства и запросом на удаление аккаунта.",
  alternates: { canonical: "/privacy-choices" },
};

export default function PrivacyChoicesPage() {
  return (
    <LegalPage title="Параметры конфиденциальности пользователей" updated="8 сентября 2026">
      <LegalSection title="Зачем эта страница">
        <p>
          Здесь — практические шаги: как ограничить доступ к данным на устройстве, что мы не делаем с вашими
          данными, и как запросить удаление аккаунта. Полный текст:{" "}
          <Link className="text-brand underline underline-offset-2" href="/privacy">
            политика конфиденциальности
          </Link>
          .
        </p>
      </LegalSection>

      <LegalSection title="Мы не продаём персональные данные">
        <p>
          Clover не продаёт персональные данные третьим лицам и не передаёт их рекламным сетям для показа чужой
          рекламы. Данные используются, чтобы работать сервис (аккаунт, лента, запись, посещаемость, уведомления,
          безопасность).
        </p>
      </LegalSection>

      <LegalSection title="Разрешения на устройстве">
        <p>Вы можете в любой момент отозвать разрешения в настройках iPhone / Android:</p>
        <ul className="list-disc space-y-1 pl-5">
          <li>
            <strong className="font-semibold text-ink">Геолокация</strong> — карта и геозона посещаемости (отметки
            на смене). Без разрешения эти функции ограничены.
          </li>
          <li>
            <strong className="font-semibold text-ink">Камера и фото</strong> — съёмка и выбор медиа для постов и
            профиля.
          </li>
          <li>
            <strong className="font-semibold text-ink">Уведомления</strong> — push о событиях в сервисе (если
            включены на устройстве).
          </li>
        </ul>
        <p>Отзыв разрешения не удаляет аккаунт — только ограничивает связанные функции.</p>
      </LegalSection>

      <LegalSection title="Данные в профиле">
        <p>
          Имя, ник, аватар, город и другой профиль можно изменить в приложении (редактирование профиля) или на
          сайте после входа, если функция доступна.
        </p>
      </LegalSection>

      <LegalSection title="Удаление аккаунта и данных">
        <p>
          Чтобы запросить удаление аккаунта и связанных персональных данных, откройте{" "}
          <Link className="text-brand underline underline-offset-2" href={SITE.supportPath}>
            форму поддержки
          </Link>{" "}
          и укажите ник/email и запрос «Удаление аккаунта». Мы обработаем обращение в разумный срок. Отдельные
          данные могут остаться, если этого требует закон (например, споры или безопасность).
        </p>
      </LegalSection>

      <LegalSection title="Вход через Google">
        <p>
          Если вы вошли через Google, управление доступом приложения к аккаунту Google — также в настройках
          Google. Отзыв доступа Google не всегда сразу удаляет профиль Clover: для полного удаления напишите нам.
        </p>
      </LegalSection>

      <LegalSection title="Вопросы">
        <p>
          Поддержка:{" "}
          <Link className="text-brand underline underline-offset-2" href={SITE.supportPath}>
            clover.com.kz/support
          </Link>
        </p>
      </LegalSection>
    </LegalPage>
  );
}
