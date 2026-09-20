import type { PlanDocument, PlanNode, PlanPoint } from "@/features/venue/lib/plan-editor-types";
import { createEmptyPlan, defaultStyle, newNodeId } from "@/features/venue/lib/plan-editor-types";

function emoji(
  id: string,
  label: string,
  x: number,
  y: number,
  size = 44,
  zIndex = 20,
  groupId?: string | null,
): PlanNode {
  return {
    id,
    kind: "emoji",
    role: "decor",
    label,
    frame: { x, y, w: size, h: size },
    style: defaultStyle({ fill: null, stroke: "transparent", strokeWidth: 0 }),
    zIndex,
    bookableId: null,
    groupId: groupId ?? null,
  };
}

function textLabel(
  id: string,
  label: string,
  x: number,
  y: number,
  w = 160,
  h = 36,
): PlanNode {
  return {
    id,
    kind: "text",
    role: "decor",
    label,
    frame: { x, y, w, h },
    style: defaultStyle({ fill: null, stroke: "transparent", strokeWidth: 0 }),
    zIndex: 25,
    bookableId: null,
  };
}

function rect(
  id: string,
  opts: {
    label: string | null;
    x: number;
    y: number;
    w: number;
    h: number;
    fill: string;
    stroke: string;
    radius?: number;
    role?: PlanNode["role"];
    bookableId?: string | null;
    zIndex?: number;
    opacity?: number;
    groupId?: string | null;
  },
): PlanNode {
  const role = opts.role ?? "decor";
  return {
    id,
    kind: "rect",
    role,
    label: opts.label,
    frame: { x: opts.x, y: opts.y, w: opts.w, h: opts.h },
    style: defaultStyle({
      fill: opts.fill,
      stroke: opts.stroke,
      radius: opts.radius ?? 14,
      opacity: opts.opacity ?? 1,
      strokeWidth: 2,
    }),
    zIndex: opts.zIndex ?? (role === "bookable" ? 10 : 2),
    bookableId: role === "bookable" ? (opts.bookableId ?? newNodeId("bk")) : null,
    groupId: opts.groupId ?? null,
  };
}

function oval(
  id: string,
  opts: {
    label: string | null;
    x: number;
    y: number;
    w: number;
    h: number;
    fill: string;
    stroke: string;
    role?: PlanNode["role"];
    bookableId?: string | null;
    zIndex?: number;
    groupId?: string | null;
  },
): PlanNode {
  const role = opts.role ?? "decor";
  return {
    id,
    kind: "ellipse",
    role,
    label: opts.label,
    frame: { x: opts.x, y: opts.y, w: opts.w, h: opts.h },
    style: defaultStyle({
      fill: opts.fill,
      stroke: opts.stroke,
      radius: 999,
      strokeWidth: 2,
    }),
    zIndex: opts.zIndex ?? (role === "bookable" ? 10 : 2),
    bookableId: role === "bookable" ? (opts.bookableId ?? newNodeId("bk")) : null,
    groupId: opts.groupId ?? null,
  };
}

function line(id: string, points: PlanPoint[], stroke = "#D4C4B0", width = 3): PlanNode {
  return {
    id,
    kind: "line",
    role: "decor",
    label: null,
    points,
    style: defaultStyle({ fill: null, stroke, strokeWidth: width, radius: 0 }),
    zIndex: 3,
    bookableId: null,
  };
}

function poly(
  id: string,
  opts: {
    label: string | null;
    points: PlanPoint[];
    fill: string;
    stroke: string;
    role?: PlanNode["role"];
    bookableId?: string | null;
    opacity?: number;
  },
): PlanNode {
  const role = opts.role ?? "decor";
  const xs = opts.points.map((p) => p.x);
  const ys = opts.points.map((p) => p.y);
  return {
    id,
    kind: "polygon",
    role,
    label: opts.label,
    points: opts.points,
    frame: {
      x: Math.min(...xs),
      y: Math.min(...ys),
      w: Math.max(...xs) - Math.min(...xs),
      h: Math.max(...ys) - Math.min(...ys),
    },
    style: defaultStyle({
      fill: opts.fill,
      stroke: opts.stroke,
      radius: 0,
      opacity: opts.opacity ?? 0.92,
      strokeWidth: 2,
    }),
    zIndex: role === "bookable" ? 10 : 4,
    bookableId: role === "bookable" ? (opts.bookableId ?? newNodeId("bk")) : null,
  };
}

/** Стулья вокруг прямоугольного стола. */
function chairsAroundRect(
  prefix: string,
  table: { x: number; y: number; w: number; h: number },
  count: { top?: number; bottom?: number; left?: number; right?: number },
  groupId?: string,
): PlanNode[] {
  const out: PlanNode[] = [];
  const size = 40;
  const gap = 8;
  const place = (side: string, n: number, getXY: (i: number) => { x: number; y: number }) => {
    for (let i = 0; i < n; i++) {
      const { x, y } = getXY(i);
      out.push(emoji(`${prefix}_${side}_${i}`, "🪑", x, y, size, 20, groupId));
    }
  };
  if (count.top) {
    place("t", count.top, (i) => ({
      x: table.x + ((i + 1) * table.w) / (count.top! + 1) - size / 2,
      y: table.y - size - gap,
    }));
  }
  if (count.bottom) {
    place("b", count.bottom, (i) => ({
      x: table.x + ((i + 1) * table.w) / (count.bottom! + 1) - size / 2,
      y: table.y + table.h + gap,
    }));
  }
  if (count.left) {
    place("l", count.left, (i) => ({
      x: table.x - size - gap,
      y: table.y + ((i + 1) * table.h) / (count.left! + 1) - size / 2,
    }));
  }
  if (count.right) {
    place("r", count.right, (i) => ({
      x: table.x + table.w + gap,
      y: table.y + ((i + 1) * table.h) / (count.right! + 1) - size / 2,
    }));
  }
  return out;
}

/** Стулья вокруг круглого стола. */
function chairsAroundOval(
  prefix: string,
  table: { x: number; y: number; w: number; h: number },
  n: number,
  groupId?: string,
): PlanNode[] {
  const cx = table.x + table.w / 2;
  const cy = table.y + table.h / 2;
  const rx = table.w / 2 + 28;
  const ry = table.h / 2 + 28;
  const size = 40;
  return Array.from({ length: n }, (_, i) => {
    const a = -Math.PI / 2 + (i * 2 * Math.PI) / n;
    return emoji(
      `${prefix}_c_${i}`,
      "🪑",
      cx + Math.cos(a) * rx - size / 2,
      cy + Math.sin(a) * ry - size / 2,
      size,
      20,
      groupId,
    );
  });
}

/** Красивый пример ресторана: бар, столы, стулья-смайлики, зоны. */
export function createCafeStarterPlan(): PlanDocument {
  const plan = createEmptyPlan();
  plan.id = "plan_restaurant_demo";
  plan.floorKey = "floor_1";
  plan.label = "1 этаж · ресторан";
  plan.canvas = {
    width: 1280,
    height: 860,
    background: "#F6F0E8",
  };

  const tWindow = { x: 70, y: 200, w: 200, h: 130 };
  const t2 = { x: 360, y: 210, w: 160, h: 160 };
  const t3 = { x: 610, y: 200, w: 200, h: 130 };
  const t4 = { x: 900, y: 210, w: 160, h: 160 };
  const tVip = { x: 120, y: 480, w: 240, h: 160 };
  const tRound = { x: 520, y: 520, w: 180, h: 180 };
  const tBooth = { x: 860, y: 500, w: 220, h: 140 };

  const gWin = "g_window";
  const g2 = "g_t2";
  const g3 = "g_t3";
  const g4 = "g_t4";
  const gVip = "g_vip";
  const gRound = "g_round";
  const gBooth = "g_booth";
  const gBar = "g_bar";

  plan.nodes = [
    // —— стены / архитектура ——
    rect("n_wall_top", {
      label: null,
      x: 40,
      y: 40,
      w: 1200,
      h: 18,
      fill: "#E8D9C8",
      stroke: "#D4C4B0",
      radius: 6,
      zIndex: 1,
    }),
    rect("n_wall_left", {
      label: null,
      x: 40,
      y: 40,
      w: 18,
      h: 780,
      fill: "#E8D9C8",
      stroke: "#D4C4B0",
      radius: 6,
      zIndex: 1,
    }),
    rect("n_wall_right", {
      label: null,
      x: 1222,
      y: 40,
      w: 18,
      h: 780,
      fill: "#E8D9C8",
      stroke: "#D4C4B0",
      radius: 6,
      zIndex: 1,
    }),
    rect("n_wall_bottom", {
      label: null,
      x: 40,
      y: 802,
      w: 1200,
      h: 18,
      fill: "#E8D9C8",
      stroke: "#D4C4B0",
      radius: 6,
      zIndex: 1,
    }),

    // окна
    rect("n_window_1", {
      label: null,
      x: 80,
      y: 48,
      w: 160,
      h: 10,
      fill: "#B8D4E8",
      stroke: "#8BB8D4",
      radius: 4,
      zIndex: 2,
    }),
    rect("n_window_2", {
      label: null,
      x: 280,
      y: 48,
      w: 160,
      h: 10,
      fill: "#B8D4E8",
      stroke: "#8BB8D4",
      radius: 4,
      zIndex: 2,
    }),
    rect("n_window_3", {
      label: null,
      x: 480,
      y: 48,
      w: 160,
      h: 10,
      fill: "#B8D4E8",
      stroke: "#8BB8D4",
      radius: 4,
      zIndex: 2,
    }),

    // бар
    rect("n_bar", {
      label: "Бар",
      x: 70,
      y: 80,
      w: 520,
      h: 72,
      fill: "#3D2C29",
      stroke: "#2A1E1C",
      radius: 16,
      zIndex: 5,
      groupId: gBar,
    }),
    oval("n_bar_stool_shadow", {
      label: null,
      x: 100,
      y: 160,
      w: 36,
      h: 20,
      fill: "#E8D9C8",
      stroke: "#D4C4B0",
      zIndex: 4,
    }),

    // кухня
    rect("n_kitchen", {
      label: "Кухня",
      x: 980,
      y: 80,
      w: 220,
      h: 100,
      fill: "#EDE9FB",
      stroke: "#5C4FA8",
      radius: 16,
      zIndex: 5,
    }),

    // вход / коридор линия
    line(
      "n_aisle",
      [
        { x: 70, y: 420 },
        { x: 1210, y: 420 },
      ],
      "#E0D2C2",
      2,
    ),
    line(
      "n_vip_rail",
      [
        { x: 400, y: 450 },
        { x: 400, y: 700 },
      ],
      "#FFA39E",
      2,
    ),

    // сцена / DJ
    poly("n_stage", {
      label: "Сцена",
      points: [
        { x: 1080, y: 680 },
        { x: 1210, y: 680 },
        { x: 1210, y: 780 },
        { x: 1040, y: 780 },
      ],
      fill: "#1A1D1E",
      stroke: "#3D2C29",
      opacity: 0.88,
    }),

    // VIP диван-зона (полигон)
    poly("n_vip_zone", {
      label: null,
      points: [
        { x: 70, y: 450 },
        { x: 400, y: 450 },
        { x: 400, y: 700 },
        { x: 70, y: 700 },
      ],
      fill: "#FFF5F0",
      stroke: "#FFA39E",
      opacity: 0.55,
    }),

    // —— столы (бронь) ——
    rect("n_table_window", {
      label: "У окна",
      ...tWindow,
      fill: "#FFA39E",
      stroke: "#B54B45",
      radius: 18,
      role: "bookable",
      bookableId: "bk_window",
      groupId: gWin,
    }),
    oval("n_table_2", {
      label: "2",
      ...t2,
      fill: "#FFA39E",
      stroke: "#B54B45",
      role: "bookable",
      bookableId: "bk_t2",
      groupId: g2,
    }),
    rect("n_table_3", {
      label: "3",
      ...t3,
      fill: "#FFA39E",
      stroke: "#B54B45",
      radius: 18,
      role: "bookable",
      bookableId: "bk_t3",
      groupId: g3,
    }),
    oval("n_table_4", {
      label: "4",
      ...t4,
      fill: "#FFA39E",
      stroke: "#B54B45",
      role: "bookable",
      bookableId: "bk_t4",
      groupId: g4,
    }),
    rect("n_table_vip", {
      label: "VIP",
      ...tVip,
      fill: "#FDF08B",
      stroke: "#9A7B00",
      radius: 20,
      role: "bookable",
      bookableId: "bk_vip",
      groupId: gVip,
    }),
    oval("n_table_round", {
      label: "Круглый",
      ...tRound,
      fill: "#FFA39E",
      stroke: "#B54B45",
      role: "bookable",
      bookableId: "bk_round",
      groupId: gRound,
    }),
    rect("n_table_booth", {
      label: "Кабинка",
      ...tBooth,
      fill: "#E3F0FC",
      stroke: "#5B9BD5",
      radius: 22,
      role: "bookable",
      bookableId: "bk_booth",
      groupId: gBooth,
    }),

    // диваны у кабинки
    rect("n_sofa_l", {
      label: null,
      x: 820,
      y: 510,
      w: 32,
      h: 120,
      fill: "#5B9BD5",
      stroke: "#3A7AB5",
      radius: 12,
      zIndex: 6,
    }),
    rect("n_sofa_r", {
      label: null,
      x: 1090,
      y: 510,
      w: 32,
      h: 120,
      fill: "#5B9BD5",
      stroke: "#3A7AB5",
      radius: 12,
      zIndex: 6,
    }),

    // —— стулья смайликами ——
    ...chairsAroundRect("ch_win", tWindow, { top: 2, bottom: 2 }, gWin),
    ...chairsAroundOval("ch_t2", t2, 4, g2),
    ...chairsAroundRect("ch_t3", t3, { top: 2, bottom: 2 }, g3),
    ...chairsAroundOval("ch_t4", t4, 4, g4),
    ...chairsAroundRect("ch_vip", tVip, { top: 2, bottom: 2, left: 1, right: 1 }, gVip),
    ...chairsAroundOval("ch_round", tRound, 6, gRound),
    ...chairsAroundRect("ch_booth", tBooth, { top: 2, bottom: 2 }, gBooth),

    // барные стулья
    emoji("e_bar_1", "🪑", 120, 158, 36, 20, gBar),
    emoji("e_bar_2", "🪑", 190, 158, 36, 20, gBar),
    emoji("e_bar_3", "🪑", 260, 158, 36, 20, gBar),
    emoji("e_bar_4", "🪑", 330, 158, 36, 20, gBar),
    emoji("e_bar_5", "🪑", 400, 158, 36, 20, gBar),
    emoji("e_bar_6", "🪑", 470, 158, 36, 20, gBar),

    textLabel("tx_hall", "Зал ресторана", 640, 70, 200, 32),
    textLabel("tx_vip", "VIP-зона", 140, 455, 120, 28),
    textLabel("tx_stage", "Сцена", 1100, 650, 100, 28),

    // атмосфера / указатели
    emoji("e_plant_1", "🌿", 60, 90, 40),
    emoji("e_plant_2", "🪴", 560, 85, 42),
    emoji("e_plant_3", "🌴", 70, 720, 48),
    emoji("e_plant_4", "🌿", 1180, 720, 40),
    emoji("e_coffee", "☕", 300, 95, 36),
    emoji("e_wine", "🍷", 360, 95, 36),
    emoji("e_cake", "🍰", 420, 95, 36),
    emoji("e_fire", "🔥", 480, 95, 34),
    emoji("e_door", "🚪", 640, 760, 52),
    emoji("e_wc", "🚻", 1140, 200, 48),
    emoji("e_access", "♿", 1140, 260, 44),
    emoji("e_no_smoke", "🚭", 1080, 200, 40),
    emoji("e_music", "🎵", 1120, 700, 40),
    emoji("e_mic", "🎤", 1165, 700, 40),
    emoji("e_star", "⭐", 200, 455, 36),
    emoji("e_heart", "❤️", 250, 455, 34),
    emoji("e_lamp_1", "💡", 430, 430, 36),
    emoji("e_lamp_2", "💡", 780, 430, 36),
    emoji("e_cam", "📷", 70, 360, 36),
    emoji("e_parking", "🅿️", 700, 760, 44),
    emoji("e_ticket", "🎟️", 760, 765, 40),
    emoji("e_chef", "👨‍🍳", 1055, 110, 44),
    emoji("e_dish", "🍽️", 1120, 110, 40),
  ] satisfies PlanNode[];

  return plan;
}

/** 2 этаж / терраса — второй план в здании. */
export function createTerraceFloorPlan(): PlanDocument {
  const plan = createEmptyPlan();
  plan.id = "plan_terrace_demo";
  plan.floorKey = "floor_2";
  plan.label = "2 этаж · терраса";
  plan.canvas = { width: 1280, height: 860, background: "#E8F5E9" };

  const t1 = { x: 120, y: 200, w: 200, h: 140 };
  const t2 = { x: 420, y: 220, w: 180, h: 180 };
  const t3 = { x: 720, y: 200, w: 200, h: 140 };
  const g1 = "g_ter_1";
  const g2 = "g_ter_2";
  const g3 = "g_ter_3";

  plan.nodes = [
    textLabel("tx_terrace", "Летняя терраса", 500, 60, 280, 36),
    rect("n_ter_rail", {
      label: null,
      x: 60,
      y: 80,
      w: 1160,
      h: 16,
      fill: "#A5D6A7",
      stroke: "#66BB6A",
      radius: 8,
      zIndex: 1,
    }),
    rect("n_ter_t1", {
      label: "T1",
      ...t1,
      fill: "#FFA39E",
      stroke: "#B54B45",
      radius: 18,
      role: "bookable",
      bookableId: "bk_ter_1",
      groupId: g1,
    }),
    oval("n_ter_t2", {
      label: "T2",
      ...t2,
      fill: "#FFA39E",
      stroke: "#B54B45",
      role: "bookable",
      bookableId: "bk_ter_2",
      groupId: g2,
    }),
    rect("n_ter_t3", {
      label: "T3",
      ...t3,
      fill: "#FFA39E",
      stroke: "#B54B45",
      radius: 18,
      role: "bookable",
      bookableId: "bk_ter_3",
      groupId: g3,
    }),
    ...chairsAroundRect("ch_ter1", t1, { top: 2, bottom: 2 }, g1),
    ...chairsAroundOval("ch_ter2", t2, 4, g2),
    ...chairsAroundRect("ch_ter3", t3, { top: 2, bottom: 2 }, g3),
    emoji("e_sun", "☀️", 100, 100, 48),
    emoji("e_plant_t1", "🌴", 80, 700, 56),
    emoji("e_plant_t2", "🌴", 1140, 700, 56),
    emoji("e_wine_t", "🍷", 560, 500, 44),
    emoji("e_stairs", "🪜", 600, 760, 48),
  ];
  return plan;
}

export function createCafeBuilding() {
  const floor1 = createCafeStarterPlan();
  const floor2 = createTerraceFloorPlan();
  return {
    version: 1 as const,
    floors: [floor1, floor2],
    activeFloorKey: floor1.floorKey,
  };
}

/** Пресет: кинозал — ряды кресел и экран. */
export function createCinemaStarterPlan(): PlanDocument {
  const plan = createEmptyPlan();
  plan.id = "plan_cinema_demo";
  plan.floorKey = "floor_1";
  plan.label = "1 этаж · кино";
  plan.canvas = { width: 1280, height: 860, background: "#1A1D1E" };
  const nodes: PlanNode[] = [
    rect("n_screen", {
      label: "Экран",
      x: 200,
      y: 60,
      w: 880,
      h: 70,
      fill: "#E8E8E8",
      stroke: "#9A9A9A",
      radius: 8,
      zIndex: 5,
    }),
    textLabel("tx_cinema", "Кинозал", 560, 20, 160, 32),
    emoji("e_popcorn", "🍿", 80, 70, 48),
    emoji("e_ticket", "🎟️", 1140, 70, 48),
    emoji("e_exit_l", "🚪", 60, 780, 48),
    emoji("e_exit_r", "🚪", 1170, 780, 48),
  ];

  const rows = 6;
  const cols = 10;
  const seatW = 70;
  const seatH = 54;
  const startX = 220;
  const startY = 200;
  for (let r = 0; r < rows; r++) {
    const gid = `g_row_${r}`;
    for (let c = 0; c < cols; c++) {
      const x = startX + c * (seatW + 16);
      const y = startY + r * (seatH + 28);
      const id = `seat_${r}_${c}`;
      nodes.push(
        rect(id, {
          label: `${String.fromCharCode(65 + r)}${c + 1}`,
          x,
          y,
          w: seatW,
          h: seatH,
          fill: "#FFA39E",
          stroke: "#B54B45",
          radius: 10,
          role: "bookable",
          bookableId: `bk_${id}`,
          groupId: gid,
        }),
      );
      nodes.push(emoji(`ch_${id}`, "🪑", x + 14, y + 6, 40, 20, gid));
    }
  }

  plan.nodes = nodes;
  return plan;
}

/** Пресет: банкет — длинные столы. */
export function createBanquetStarterPlan(): PlanDocument {
  const plan = createEmptyPlan();
  plan.id = "plan_banquet_demo";
  plan.floorKey = "floor_1";
  plan.label = "1 этаж · банкет";
  plan.canvas = { width: 1280, height: 860, background: "#F8F4FC" };
  const nodes: PlanNode[] = [
    textLabel("tx_banquet", "Банкетный зал", 520, 40, 240, 36),
    rect("n_head", {
      label: "Президиум",
      x: 400,
      y: 90,
      w: 480,
      h: 90,
      fill: "#FDF08B",
      stroke: "#9A7B00",
      radius: 16,
      role: "bookable",
      bookableId: "bk_head",
      groupId: "g_head",
    }),
    ...chairsAroundRect("ch_head", { x: 400, y: 90, w: 480, h: 90 }, { bottom: 6 }, "g_head"),
    emoji("e_cake", "🎂", 620, 100, 48),
    emoji("e_flowers", "💐", 80, 100, 48),
    emoji("e_flowers2", "💐", 1150, 100, 48),
    emoji("e_music", "🎵", 1100, 780, 44),
    emoji("e_dance", "💃", 1040, 780, 44),
  ];

  for (let i = 0; i < 3; i++) {
    const gid = `g_banquet_${i}`;
    const table = { x: 120 + i * 380, y: 320, w: 280, h: 100 };
    nodes.push(
      rect(`n_banquet_${i}`, {
        label: `Стол ${i + 1}`,
        ...table,
        fill: "#FFA39E",
        stroke: "#B54B45",
        radius: 18,
        role: "bookable",
        bookableId: `bk_banquet_${i}`,
        groupId: gid,
      }),
    );
    nodes.push(
      ...chairsAroundRect(`ch_b_${i}`, table, { top: 3, bottom: 3, left: 1, right: 1 }, gid),
    );
  }

  // круглый центральный
  const round = { x: 520, y: 520, w: 220, h: 220 };
  nodes.push(
    oval("n_round_center", {
      label: "Центр",
      ...round,
      fill: "#EDE9FB",
      stroke: "#5C4FA8",
      role: "bookable",
      bookableId: "bk_center",
      groupId: "g_center",
    }),
  );
  nodes.push(...chairsAroundOval("ch_center", round, 8, "g_center"));

  plan.nodes = nodes;
  return plan;
}

export function exportPlanPayload(plan: PlanDocument) {
  return {
    schema_version: 1,
    venue_id: "mock_venue",
    plan: {
      id: plan.id,
      floor_key: plan.floorKey,
      label: plan.label,
      version: plan.version,
      status: plan.status,
      canvas: {
        width: plan.canvas.width,
        height: plan.canvas.height,
        unit: "px",
        background: plan.canvas.background,
      },
      nodes: plan.nodes.map((n) => ({
        id: n.id,
        kind: n.kind,
        role: n.role,
        label: n.label,
        frame: n.frame ?? null,
        points: n.points ?? null,
        holes: n.holes ?? null,
        rotation: n.rotation ?? 0,
        group_id: n.groupId ?? null,
        style: {
          fill: n.style.fill,
          stroke: n.style.stroke,
          stroke_width: n.style.strokeWidth,
          radius: n.style.radius,
          opacity: n.style.opacity,
        },
        z_index: n.zIndex,
        bookable_id: n.bookableId,
      })),
    },
    bookables: plan.nodes
      .filter((n) => n.role === "bookable")
      .map((n) => ({
        id: n.bookableId ?? newNodeId("bk"),
        label: n.label ?? "Место",
        capacity: 2,
        selection: "single",
      })),
    client_view: {
      mode: "visual_and_list",
      note: "Клиент рисунок не правит — только кликает bookable",
    },
  };
}
