/** Мок логики брони: bookable + occasion + inventory. См. docs/business/venue-seating.md */

export type BookableKind = "ticket" | "seat" | "zone";

export type BookableInventoryState = "free" | "held" | "taken";

export type OccasionKind = "session" | "slot";

export type MockBookable = {
  id: string;
  kind: BookableKind;
  label: string;
  capacity: number;
  priceHint: string;
  /** Привязка к фигуре на плане (уровень C). */
  planNodeId: string | null;
  selection: "single" | "multi";
};

export type MockOccasion = {
  id: string;
  kind: OccasionKind;
  title: string;
  /** Человекочитаемо */
  whenLabel: string;
  startsAt: string;
  endsAt: string | null;
};

export type MockInventoryRow = {
  bookableId: string;
  state: BookableInventoryState;
};

export type MockReservation = {
  id: string;
  guestName: string;
  bookableLabel: string;
  occasionLabel: string;
  guests: number;
  comment: string;
  status: "requested" | "confirmed" | "declined";
};

const CAFE_BOOKABLES: MockBookable[] = [
  {
    id: "bk_window",
    kind: "seat",
    label: "У окна",
    capacity: 4,
    priceHint: "от 0 ₸",
    planNodeId: "n_table_window",
    selection: "single",
  },
  {
    id: "bk_t2",
    kind: "seat",
    label: "Стол 2",
    capacity: 2,
    priceHint: "от 0 ₸",
    planNodeId: "n_table_2",
    selection: "single",
  },
  {
    id: "bk_t3",
    kind: "seat",
    label: "Стол 3",
    capacity: 4,
    priceHint: "от 0 ₸",
    planNodeId: "n_table_3",
    selection: "single",
  },
  {
    id: "bk_vip",
    kind: "zone",
    label: "VIP",
    capacity: 6,
    priceHint: "от 15 000 ₸",
    planNodeId: "n_table_vip",
    selection: "single",
  },
  {
    id: "bk_booth",
    kind: "seat",
    label: "Кабинка",
    capacity: 4,
    priceHint: "от 8 000 ₸",
    planNodeId: "n_table_booth",
    selection: "single",
  },
  {
    id: "bk_ter_1",
    kind: "seat",
    label: "Терраса T1",
    capacity: 4,
    priceHint: "от 0 ₸",
    planNodeId: "n_ter_t1",
    selection: "single",
  },
];

const CINEMA_BOOKABLES: MockBookable[] = [
  {
    id: "bk_std",
    kind: "ticket",
    label: "Стандарт",
    capacity: 1,
    priceHint: "2 500 ₸",
    planNodeId: null,
    selection: "multi",
  },
  {
    id: "bk_vip_t",
    kind: "ticket",
    label: "VIP",
    capacity: 1,
    priceHint: "4 500 ₸",
    planNodeId: null,
    selection: "multi",
  },
  ...Array.from({ length: 8 }, (_, i) => ({
    id: `bk_seat_a${i + 1}`,
    kind: "seat" as const,
    label: `A${i + 1}`,
    capacity: 1,
    priceHint: "2 500 ₸",
    planNodeId: `seat_0_${i}`,
    selection: "multi" as const,
  })),
];

const POETRY_BOOKABLES: MockBookable[] = [
  {
    id: "bk_entry",
    kind: "ticket",
    label: "Вход",
    capacity: 1,
    priceHint: "3 000 ₸",
    planNodeId: null,
    selection: "multi",
  },
  {
    id: "bk_vip_p",
    kind: "ticket",
    label: "VIP ряд",
    capacity: 1,
    priceHint: "6 000 ₸",
    planNodeId: null,
    selection: "multi",
  },
];

const CAFE_OCCASIONS: MockOccasion[] = [
  {
    id: "occ_fri_19",
    kind: "slot",
    title: "Ужин",
    whenLabel: "Пт 19:00 – 21:00",
    startsAt: "2026-09-18T19:00:00+05:00",
    endsAt: "2026-09-18T21:00:00+05:00",
  },
  {
    id: "occ_fri_21",
    kind: "slot",
    title: "Поздний слот",
    whenLabel: "Пт 21:00 – 23:00",
    startsAt: "2026-09-18T21:00:00+05:00",
    endsAt: "2026-09-18T23:00:00+05:00",
  },
  {
    id: "occ_sat_13",
    kind: "slot",
    title: "Обед",
    whenLabel: "Сб 13:00 – 15:00",
    startsAt: "2026-09-19T13:00:00+05:00",
    endsAt: "2026-09-19T15:00:00+05:00",
  },
];

const CINEMA_OCCASIONS: MockOccasion[] = [
  {
    id: "occ_film_17",
    kind: "session",
    title: "Сеанс 17:00",
    whenLabel: "Сегодня 17:00",
    startsAt: "2026-09-16T17:00:00+05:00",
    endsAt: null,
  },
  {
    id: "occ_film_20",
    kind: "session",
    title: "Сеанс 20:00",
    whenLabel: "Сегодня 20:00",
    startsAt: "2026-09-16T20:00:00+05:00",
    endsAt: null,
  },
];

const POETRY_OCCASIONS: MockOccasion[] = [
  {
    id: "occ_poetry",
    kind: "session",
    title: "Вечер поэзии",
    whenLabel: "Сб 19:30",
    startsAt: "2026-09-19T19:30:00+05:00",
    endsAt: null,
  },
];

function inventoryFor(
  bookables: MockBookable[],
  pattern: BookableInventoryState[],
): MockInventoryRow[] {
  return bookables.map((b, i) => ({
    bookableId: b.id,
    state: pattern[i % pattern.length]!,
  }));
}

const CAFE_INV: Record<string, MockInventoryRow[]> = {
  occ_fri_19: inventoryFor(CAFE_BOOKABLES, ["free", "held", "taken", "free", "free", "held"]),
  occ_fri_21: inventoryFor(CAFE_BOOKABLES, ["free", "free", "free", "taken", "held", "free"]),
  occ_sat_13: inventoryFor(CAFE_BOOKABLES, ["taken", "taken", "free", "free", "free", "free"]),
};

const CINEMA_INV: Record<string, MockInventoryRow[]> = {
  occ_film_17: inventoryFor(CINEMA_BOOKABLES, ["free", "free", "taken", "held", "free", "taken", "free", "free"]),
  occ_film_20: inventoryFor(CINEMA_BOOKABLES, ["held", "taken", "free", "free", "taken", "free", "held", "free"]),
};

const POETRY_INV: Record<string, MockInventoryRow[]> = {
  occ_poetry: inventoryFor(POETRY_BOOKABLES, ["free", "held"]),
};

const RESERVATIONS: Record<string, MockReservation[]> = {
  cafe: [
    {
      id: "r1",
      guestName: "Айгерим",
      bookableLabel: "У окна",
      occasionLabel: "Пт 19:00 – 21:00",
      guests: 3,
      comment: "У окна, пожалуйста",
      status: "requested",
    },
    {
      id: "r2",
      guestName: "Данияр",
      bookableLabel: "Стол 2",
      occasionLabel: "Пт 19:00 – 21:00",
      guests: 2,
      comment: "",
      status: "confirmed",
    },
  ],
  cinema: [
    {
      id: "r3",
      guestName: "Сабина",
      bookableLabel: "A3, A4",
      occasionLabel: "Сегодня 20:00",
      guests: 2,
      comment: "Рядом",
      status: "requested",
    },
  ],
  poetry: [
    {
      id: "r4",
      guestName: "Нурлан",
      bookableLabel: "VIP ряд",
      occasionLabel: "Сб 19:30",
      guests: 1,
      comment: "",
      status: "requested",
    },
  ],
};

export function bookablesFor(venueId: string): MockBookable[] {
  if (venueId === "cinema") return CINEMA_BOOKABLES;
  if (venueId === "poetry") return POETRY_BOOKABLES;
  return CAFE_BOOKABLES;
}

export function occasionsFor(venueId: string): MockOccasion[] {
  if (venueId === "cinema") return CINEMA_OCCASIONS;
  if (venueId === "poetry") return POETRY_OCCASIONS;
  return CAFE_OCCASIONS;
}

export function inventoryForOccasion(
  venueId: string,
  occasionId: string,
): MockInventoryRow[] {
  const map =
    venueId === "cinema" ? CINEMA_INV : venueId === "poetry" ? POETRY_INV : CAFE_INV;
  return map[occasionId] ?? inventoryFor(bookablesFor(venueId), ["free"]);
}

export function reservationsFor(venueId: string): MockReservation[] {
  return RESERVATIONS[venueId] ?? RESERVATIONS.cafe!;
}

export function ladderLabel(venueId: string): string {
  if (venueId === "cinema") return "A+C · билеты и места на схеме";
  if (venueId === "poetry") return "A · только билеты";
  return "B+C · места и схема";
}

export function kindLabel(kind: BookableKind): string {
  if (kind === "ticket") return "Билет";
  if (kind === "zone") return "Зона";
  return "Место";
}

export function stateLabel(state: BookableInventoryState): string {
  if (state === "held") return "Hold";
  if (state === "taken") return "Занято";
  return "Свободно";
}

export function stateClass(state: BookableInventoryState): string {
  if (state === "held") return "bg-functional-soft-orange text-ink";
  if (state === "taken") return "bg-functional-soft-red text-ink";
  return "bg-success-soft text-ink";
}

export function occasionKindLabel(kind: OccasionKind): string {
  return kind === "session" ? "Сеанс" : "Слот";
}
