/** Гайд «Ресурсы» — те же ключи, что mobile ResourcesGuideCatalog. */

export type ResourcesGuideTopic = "overview" | "locations" | "filters" | "space_plans";

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
        body: "Три слоя: места (где), схемы пространства (как выглядит зал — рисуете на сайте), фильтры (как классифицировать). Вместе — контекст посту и витрине.",
      },
      {
        title: "Чего это не делает",
        body: "Не выбирает город ленты и карты. Схему присваивают компании / точке — сама запись и посещаемость остаются отдельными сервисами.",
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
    topic: "space_plans",
    cardTitle: "Схемы пространства",
    cardSubtitle: "План зала для брони",
    pageTitle: "Схемы пространства",
    lead:
      "Геометрия зала живёт в Ресурсах. Рисуете только на сайте; мобилка смотрит опубликованный план. При создании компании можно присвоить схему.",
    steps: [
      {
        title: "Создать",
        body: "Ресурсы → Схемы → новая или шаблон (кафе / кино). Откроется рисовалка.",
      },
      {
        title: "Опубликовать",
        body: "Черновик не виден гостю. После «Опубликовать» схему можно привязать к заведению / точке.",
      },
      {
        title: "Бронь",
        body: "Гость выбирает место на схеме или списком — один и тот же объект брони.",
      },
    ],
    ctaLabel: "Открыть схемы",
    ctaHref: "/app/settings/resources/space-plans",
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
