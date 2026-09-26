/**
 * Сумасшедший emoji-эталон: много смайлов, яркие зоны, «парк развлечений».
 * Для вставки в редактор / шаблон «Emoji chaos».
 */

import { createEmptyPlan, defaultStyle } from "@/features/venue/lib/plan-editor-types";
import type { PlanDocument, PlanNode } from "@/features/venue/lib/plan-editor-types";
import type { VenueBuildingDraft } from "@/features/venue/lib/plan-floors";

function emoji(
  id: string,
  char: string,
  x: number,
  y: number,
  size = 44,
  z = 22,
  groupId?: string | null,
): PlanNode {
  return {
    id,
    kind: "emoji",
    role: "decor",
    label: char,
    frame: { x, y, w: size, h: size },
    style: defaultStyle({ fill: null, stroke: "transparent", strokeWidth: 0 }),
    zIndex: z,
    bookableId: null,
    groupId: groupId ?? null,
  };
}

function labelText(id: string, text: string, x: number, y: number, w = 280): PlanNode {
  return {
    id,
    kind: "text",
    role: "decor",
    label: text,
    frame: { x, y, w, h: 36 },
    style: defaultStyle({ fill: null, stroke: "transparent", strokeWidth: 0 }),
    zIndex: 30,
    bookableId: null,
  };
}

function softRect(
  id: string,
  label: string | null,
  x: number,
  y: number,
  w: number,
  h: number,
  fill: string,
  stroke: string,
  opts?: { role?: "decor" | "bookable"; bookableId?: string | null; radius?: number; rot?: number; z?: number; groupId?: string },
): PlanNode {
  const role = opts?.role ?? "decor";
  return {
    id,
    kind: "rect",
    role,
    label,
    frame: { x, y, w, h },
    rotation: opts?.rot,
    groupId: opts?.groupId ?? null,
    style: defaultStyle({
      fill,
      stroke,
      strokeWidth: 2,
      radius: opts?.radius ?? 18,
      opacity: 0.95,
    }),
    zIndex: opts?.z ?? (role === "bookable" ? 10 : 2),
    bookableId: role === "bookable" ? (opts?.bookableId ?? id.replace(/^n_/, "bk_")) : null,
  };
}

function softOval(
  id: string,
  label: string | null,
  x: number,
  y: number,
  w: number,
  h: number,
  fill: string,
  stroke: string,
  opts?: { role?: "decor" | "bookable"; bookableId?: string | null; rot?: number; groupId?: string },
): PlanNode {
  const role = opts?.role ?? "decor";
  return {
    id,
    kind: "ellipse",
    role,
    label,
    frame: { x, y, w, h },
    rotation: opts?.rot,
    groupId: opts?.groupId ?? null,
    style: defaultStyle({
      fill,
      stroke,
      strokeWidth: 2,
      radius: 999,
      opacity: 0.95,
    }),
    zIndex: role === "bookable" ? 10 : 3,
    bookableId: role === "bookable" ? (opts?.bookableId ?? null) : null,
  };
}

function buildFloor1(): PlanDocument {
  const plan = createEmptyPlan();
  plan.id = "plan_crazy_floor_1";
  plan.floorKey = "floor_1";
  plan.label = "1 · Emoji Carnival";
  plan.status = "draft";
  plan.canvas = { width: 1400, height: 920, background: "#1A1028" };

  const nodes: PlanNode[] = [
    softRect("n_stage_glow", null, 60, 50, 1280, 140, "#2D1B4E", "#FF6BCB", {
      radius: 28,
      z: 0,
    }),
    labelText("n_title", "🌈 CLOVER EMOJI CARNIVAL", 90, 70, 520),
    labelText("n_sub", "бронь = цветные подиумы · смайлы = атмосфера", 90, 112, 560),

    // Радуга emoji-ряд сверху
    ...[
      "🦄",
      "🪩",
      "🔥",
      "🍕",
      "🧋",
      "🎧",
      "🛸",
      "🐸",
      "🫶",
      "✨",
      "🌮",
      "🦇",
      "🛼",
      "🧃",
      "🧿",
    ].map((c, i) => emoji(`n_rain_${i}`, c, 90 + i * 78, 160, 52, 25)),

    // DJ / сцена
    softRect("n_dj_booth", "DJ", 980, 70, 300, 100, "#FF6BCB", "#FFFFFF", {
      role: "bookable",
      bookableId: "bk_dj",
      radius: 20,
      z: 10,
    }),
    emoji("n_dj_emoji", "🎧", 1090, 88, 56, 26),

    // Дорожка
    {
      id: "n_runway",
      kind: "line",
      role: "decor",
      label: null,
      points: [
        { x: 120, y: 250 },
        { x: 1280, y: 250 },
      ],
      style: defaultStyle({ fill: null, stroke: "#FDF08B", strokeWidth: 6 }),
      zIndex: 4,
      bookableId: null,
    },

    // Зона «еда» — polygon
    {
      id: "n_food_zone",
      kind: "polygon",
      role: "bookable",
      label: "FOOD",
      points: [
        { x: 80, y: 280 },
        { x: 420, y: 280 },
        { x: 460, y: 480 },
        { x: 60, y: 500 },
      ],
      style: defaultStyle({
        fill: "#FF8A5B",
        stroke: "#FFD166",
        strokeWidth: 3,
        radius: 0,
        opacity: 0.88,
      }),
      zIndex: 8,
      bookableId: "bk_food_zone",
    },
    emoji("n_food_1", "🍕", 120, 310, 48),
    emoji("n_food_2", "🍜", 190, 320, 48),
    emoji("n_food_3", "🍩", 260, 305, 48),
    emoji("n_food_4", "🥑", 140, 390, 44),
    emoji("n_food_5", "🍣", 220, 400, 44),
    emoji("n_food_6", "🍦", 300, 380, 44),
    labelText("n_food_lbl", "фудкорт · бронь зоны", 100, 450, 260),

    // Столы-«планеты» с орбитами emoji
    softOval("n_planet_a", "🪐", 560, 300, 160, 160, "#7B61FF", "#E0D4FF", {
      role: "bookable",
      bookableId: "bk_planet_a",
      groupId: "g_planet_a",
    }),
    emoji("n_pa1", "👽", 520, 280, 40, 24, "g_planet_a"),
    emoji("n_pa2", "🚀", 720, 320, 40, 24, "g_planet_a"),
    emoji("n_pa3", "⭐", 600, 460, 40, 24, "g_planet_a"),

    softOval("n_planet_b", "🌎", 820, 300, 160, 160, "#00C2A8", "#B8FFF2", {
      role: "bookable",
      bookableId: "bk_planet_b",
      groupId: "g_planet_b",
      rot: -12,
    }),
    emoji("n_pb1", "🦜", 780, 270, 40, 24, "g_planet_b"),
    emoji("n_pb2", "🌴", 970, 340, 44, 24, "g_planet_b"),
    emoji("n_pb3", "🐚", 860, 460, 40, 24, "g_planet_b"),

    // Кабинки-сердца
    softRect("n_heart_1", "💕", 1100, 290, 140, 120, "#FF4D6D", "#FFB3C1", {
      role: "bookable",
      bookableId: "bk_heart_1",
      radius: 28,
      rot: 6,
      groupId: "g_heart_1",
    }),
    emoji("n_h1a", "😘", 1120, 250, 42, 24, "g_heart_1"),
    emoji("n_h1b", "🌹", 1200, 250, 42, 24, "g_heart_1"),

    softRect("n_heart_2", "💜", 1100, 450, 140, 120, "#9B5DE5", "#E0BBE4", {
      role: "bookable",
      bookableId: "bk_heart_2",
      radius: 28,
      rot: -8,
    }),
    emoji("n_h2", "🫶", 1145, 480, 48),

    // Танцпол path
    {
      id: "n_dancefloor",
      kind: "path",
      role: "bookable",
      label: "DANCE",
      points: [
        { x: 200, y: 560 },
        { x: 700, y: 540 },
        { x: 760, y: 780 },
        { x: 160, y: 800 },
      ],
      style: defaultStyle({
        fill: "#00F5D4",
        stroke: "#FFFFFF",
        strokeWidth: 4,
        radius: 0,
        opacity: 0.75,
      }),
      zIndex: 7,
      bookableId: "bk_dance",
    },
    ...["💃", "🕺", "🪩", "🎤", "🎷", "🥁", "🎸", "🥳", "🤩", "😎"].map((c, i) =>
      emoji(`n_dance_${i}`, c, 240 + (i % 5) * 90, 600 + Math.floor(i / 5) * 70, 46),
    ),

    // VIP облако
    softOval("n_vip_cloud", "VIP", 860, 580, 280, 160, "#FDF08B", "#FF6BCB", {
      role: "bookable",
      bookableId: "bk_vip_cloud",
      rot: 4,
    }),
    emoji("n_vip1", "👑", 920, 560, 48),
    emoji("n_vip2", "🥂", 1000, 620, 48),
    emoji("n_vip3", "💎", 1080, 560, 48),
    emoji("n_vip4", "🍾", 960, 680, 44),

    // Низ: зоопарк декора
    ...["🐶", "🐱", "🦊", "🐻", "🐼", "🐨", "🐯", "🦁", "🐮", "🐷", "🐸", "🐵"].map(
      (c, i) => emoji(`n_zoo_${i}`, c, 80 + i * 74, 840, 42, 20),
    ),

    labelText("n_footer", "чем больше emoji — тем веселее витрина ✨", 80, 790, 420),
  ];

  plan.nodes = nodes;
  return plan;
}

function buildFloor2(): PlanDocument {
  const plan = createEmptyPlan();
  plan.id = "plan_crazy_floor_2";
  plan.floorKey = "floor_2";
  plan.label = "2 · Cosmic Lounge";
  plan.status = "draft";
  plan.canvas = { width: 1400, height: 920, background: "#0B132B" };

  const nodes: PlanNode[] = [
    labelText("n2_title", "🛸 COSMIC LOUNGE", 80, 60, 400),
    ...["🌑", "🌒", "🌓", "🌔", "🌕", "🌖", "🌗", "🌘"].map((c, i) =>
      emoji(`n2_moon_${i}`, c, 80 + i * 70, 120, 48),
    ),
    softOval("n2_pod_1", "A", 200, 280, 200, 200, "#3A86FF", "#90E0EF", {
      role: "bookable",
      bookableId: "bk_pod_a",
    }),
    softOval("n2_pod_2", "B", 520, 280, 200, 200, "#FF006E", "#FF99C8", {
      role: "bookable",
      bookableId: "bk_pod_b",
    }),
    softOval("n2_pod_3", "C", 840, 280, 200, 200, "#8338EC", "#C77DFF", {
      role: "bookable",
      bookableId: "bk_pod_c",
    }),
    emoji("n2_a", "🧑‍🚀", 260, 340, 56),
    emoji("n2_b", "👾", 580, 340, 56),
    emoji("n2_c", "🤖", 900, 340, 56),
    {
      id: "n2_orbit",
      kind: "path",
      role: "decor",
      label: null,
      points: [
        { x: 150, y: 600 },
        { x: 400, y: 520 },
        { x: 700, y: 640 },
        { x: 1000, y: 540 },
        { x: 1250, y: 620 },
      ],
      style: defaultStyle({ fill: null, stroke: "#FDF08B", strokeWidth: 3 }),
      zIndex: 5,
      bookableId: null,
    },
    ...["☄️", "🌟", "🪐", "🌌", "🔭", "📡"].map((c, i) =>
      emoji(`n2_space_${i}`, c, 200 + i * 160, 700, 52),
    ),
    softRect("n2_bar", "Nebula Bar", 1000, 720, 280, 100, "#2D1B4E", "#FF6BCB", {
      role: "bookable",
      bookableId: "bk_nebula_bar",
      radius: 22,
    }),
    emoji("n2_bar_e", "🍸", 1110, 740, 52),
  ];

  plan.nodes = nodes;
  return plan;
}

/** Безумный 2-этажный emoji-парк. */
export const PLAN_CRAZY_EMOJI_BUILDING: VenueBuildingDraft = {
  version: 1,
  activeFloorKey: "floor_1",
  floors: [buildFloor1(), buildFloor2()],
};

export function planCrazyEmojiJson(): string {
  return JSON.stringify(PLAN_CRAZY_EMOJI_BUILDING, null, 2);
}
