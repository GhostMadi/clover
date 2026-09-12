/** Гайд «Посещаемость» внутри хаба. См. docs/business/attendance-guide.md */

export type AttendanceGuideContent = {
  pageTitle: string;
  lead: string;
  steps: { title: string; body: string }[];
};

export const ATTENDANCE_GUIDE: AttendanceGuideContent = {
  pageTitle: "Что такое посещаемость",
  lead:
    "Кабинет хозяина компании: смена, люди, часы и зарплата в одном месте.",
  steps: [
    {
      title: "Сегодня",
      body: "День компании: кто на смене, кто не отметился, заявки на проверку.",
    },
    {
      title: "Люди",
      body: "Работники: пригласить, активировать, архив.",
    },
    {
      title: "Дежурства",
      body: "Ростер на день, отсутствия и сверхурочные на согласование.",
    },
    {
      title: "Табель",
      body: "Часы за период и выгрузка для учёта.",
    },
    {
      title: "Зарплата",
      body: "Правила оплаты и превью начислений.",
    },
    {
      title: "Аналитика",
      body: "Сводка по команде, дню и человеку.",
    },
    {
      title: "Настройки",
      body: "Геозона, типы отметок и правила дежурств.",
    },
  ],
};
