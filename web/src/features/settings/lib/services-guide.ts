/** Общий гайд сервисов — docs/business/services-guide.md */

export type ServicesGuideTopic = "booking" | "attendance" | "resources";

export type ServicesGuideStep = {
  title: string;
  body: string;
};

export type ServicesGuideContent = {
  topic: ServicesGuideTopic;
  cardTitle: string;
  cardSubtitle: string;
  pageTitle: string;
  lead: string;
  steps: ServicesGuideStep[];
  service: "booking" | "attendance" | "resources";
};

export const SERVICES_GUIDE: ServicesGuideContent[] = [
  {
    topic: "booking",
    service: "booking",
    cardTitle: "Запись",
    cardSubtitle: "Услуги, inbox и расписание",
    pageTitle: "Запись",
    lead:
      "Сервис для хозяина витрины: услуги, заявки клиентов и расписание. Клиент бронирует без вашего тега хозяина.",
    steps: [
      {
        title: "Тег",
        body: "Включите тег booking на профиле — появится хаб «Запись» в настройках и ярлык на профиле.",
      },
      {
        title: "Услуги и inbox",
        body: "Создайте услуги, принимайте и ведите заявки в inbox хозяина.",
      },
      {
        title: "Клиент",
        body: "«Мои бронирования» — где вы клиент. Тег хозяина для этого не нужен.",
      },
      {
        title: "Исполнители",
        body: "Можно пригласить исполнителя карточкой в чат — он примет или отклонит приглашение.",
      },
    ],
  },
  {
    topic: "attendance",
    service: "attendance",
    cardTitle: "Посещаемость",
    cardSubtitle: "Компании, геозона и punch",
    pageTitle: "Посещаемость",
    lead: "Учёт смен и присутствия: компании, геозона, работники и punch с телефона.",
    steps: [
      {
        title: "Теги",
        body: "attendance — admin компании; attendanceWork — работник (punch).",
      },
      {
        title: "Компания",
        body: "Создайте компанию, настройте геозону и пригласите людей в команду.",
      },
      {
        title: "Punch",
        body: "Работник отмечает приход/уход с телефона в зоне компании.",
      },
      {
        title: "Отчёты",
        body: "Admin видит табель, аналитику и настройки оплаты смен.",
      },
    ],
  },
  {
    topic: "resources",
    service: "resources",
    cardTitle: "Ресурсы",
    cardSubtitle: "Места и фильтры витрины",
    pageTitle: "Ресурсы",
    lead: "Личный набор автора: местоположения для постов и свои фильтры сетки профиля.",
    steps: [
      {
        title: "Тег",
        body: "Тег resources открывает хаб «Ресурсы» в настройках.",
      },
      {
        title: "Местоположения",
        body: "Сохраните адреса один раз и выбирайте их в композере поста.",
      },
      {
        title: "Фильтры витрины",
        body: "Свои категории и значения — чипы на профиле и метки у постов. Не путать с фильтром ленты Home.",
      },
    ],
  },
];

export function getServicesGuide(topic: string): ServicesGuideContent | null {
  const key = topic.trim();
  return SERVICES_GUIDE.find((item) => item.topic === key) ?? null;
}
