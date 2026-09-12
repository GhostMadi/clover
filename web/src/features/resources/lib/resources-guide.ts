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
    cardSubtitle: "Идея сервиса",
    pageTitle: "Что такое ресурсы",
    lead:
      "Ресурсы — ваш личный справочник для витрины профиля: не лента города и не «настройки аккаунта», а то, чем вы наполняете публикации и как гости читают ваш профиль.",
    steps: [
      {
        title: "Зачем",
        body: "Чтобы одни и те же места и метки не набирать каждый раз заново — и чтобы профиль собирался в понятную витрину, а не в свалку постов.",
      },
      {
        title: "Из чего состоит",
        body: "Два слоя: места (где происходило) и фильтры (как это классифицировать). Вместе они дают контекст посту и навигацию гостю по вашему профилю.",
      },
      {
        title: "Чего это не делает",
        body: "Не выбирает город ленты и карты, не заменяет запись или посещаемость. Только справочник автора витрины.",
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
