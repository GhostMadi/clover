/** Гайд «Ресурсы» — те же ключи, что mobile ResourcesGuideCatalog. */

export type ResourcesGuideTopic = "overview" | "locations" | "filters";

export type ResourcesGuideStep = {
  title: string;
  body: string;
};

export type ResourcesGuideContent = {
  topic: ResourcesGuideTopic;
  cardTitle: string;
  cardSubtitle: string;
  pageTitle: string;
  lead: string;
  steps: ResourcesGuideStep[];
  ctaLabel: string | null;
  ctaHref: string | null;
};

export const RESOURCES_GUIDE: ResourcesGuideContent[] = [
  {
    topic: "overview",
    cardTitle: "Что такое ресурсы",
    cardSubtitle: "Зачем сервис и с чего начать",
    pageTitle: "Что такое ресурсы",
    lead:
      "Ресурсы — личный набор инструментов автора витрины: места для постов и категории, по которым вы и гости сужаете сетку профиля.",
    steps: [
      {
        title: "Местоположения",
        body: "Сохраните адреса один раз и выбирайте их при создании поста или ивента — не вводить точку заново.",
      },
      {
        title: "Фильтры витрины",
        body: "Свои категории и значения (например «Услуга → Стрижка»). Чипы на профиле и метки в композере поста.",
      },
      {
        title: "Как начать",
        body: "Сначала добавьте место, затем создайте категорию фильтров. В новом посте выберите место и отметьте значения.",
      },
      {
        title: "Не путать",
        body: "Город ленты и фильтр Home — другое. Ресурсы не меняют, какой город смотрите в ленте или на карте.",
      },
    ],
    ctaLabel: null,
    ctaHref: null,
  },
  {
    topic: "locations",
    cardTitle: "Местоположения",
    cardSubtitle: "Точки на карте для постов",
    pageTitle: "Местоположения",
    lead:
      "Личный справочник мест: адрес + координаты. Только ваши точки, не город ленты и не зоны доставки.",
    steps: [
      {
        title: "Создать",
        body: "Ресурсы → Местоположения → Добавить. Поставьте пин и укажите адрес.",
      },
      {
        title: "Использовать",
        body: "В композере поста выберите активное место из списка.",
      },
      {
        title: "Активность",
        body: "Неактивное место остаётся в списке, но его нельзя выбрать в новом посте.",
      },
    ],
    ctaLabel: "Открыть местоположения",
    ctaHref: "/app/settings/resources/locations",
  },
  {
    topic: "filters",
    cardTitle: "Фильтры витрины",
    cardSubtitle: "Категории для сетки профиля",
    pageTitle: "Фильтры витрины",
    lead:
      "Свои категории и значения, чтобы гости (и вы) фильтровали посты на профиле. Это не фильтр ленты Home.",
    steps: [
      {
        title: "Создать категорию",
        body: "Ресурсы → Фильтры → новая категория и значения внутри неё.",
      },
      {
        title: "На профиле",
        body: "Чипы над сеткой сужают показ постов с выбранными метками.",
      },
      {
        title: "В посте",
        body: "При публикации отметьте, к каким значениям относится пост.",
      },
    ],
    ctaLabel: "Открыть фильтры",
    ctaHref: "/app/settings/resources/filters",
  },
];

export function getResourcesGuide(topic: string): ResourcesGuideContent | null {
  return RESOURCES_GUIDE.find((item) => item.topic === topic) ?? null;
}
