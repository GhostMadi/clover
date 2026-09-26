/**
 * Полный эталон JSON здания для AI / «Вставить JSON».
 * Покрывает: 2 этажа, все kind, decor|bookable, group, rotation, holes, line/polygon/path/emoji/text.
 * Процесс: docs/business/space-plan-resources.md · docs/business/venue-plan.full.example.json
 */

import type { VenueBuildingDraft } from "@/features/venue/lib/plan-floors";

export const PLAN_FULL_EXAMPLE_BUILDING: VenueBuildingDraft = {
  version: 1,
  activeFloorKey: "floor_1",
  floors: [
    {
      id: "plan_full_floor_1",
      floorKey: "floor_1",
      label: "1 этаж · зал",
      version: 1,
      status: "draft",
      canvas: { width: 1280, height: 860, background: "#F7F7F8" },
      nodes: [
        {
          id: "n_floor_bg",
          kind: "rect",
          role: "decor",
          label: null,
          frame: { x: 40, y: 40, w: 1200, h: 780 },
          style: {
            fill: "#FFFFFF",
            stroke: "#E8E8E8",
            strokeWidth: 2,
            radius: 24,
            opacity: 1,
          },
          zIndex: 0,
          bookableId: null,
        },
        {
          id: "n_bar",
          kind: "rect",
          role: "decor",
          label: "Бар",
          frame: { x: 80, y: 70, w: 520, h: 90 },
          style: {
            fill: "#E8E8E8",
            stroke: "#CCCCCC",
            strokeWidth: 2,
            radius: 12,
            opacity: 1,
          },
          zIndex: 1,
          bookableId: null,
        },
        {
          id: "n_title",
          kind: "text",
          role: "decor",
          label: "Зал Clover · полный пример",
          frame: { x: 640, y: 80, w: 420, h: 40 },
          style: {
            fill: null,
            stroke: "transparent",
            strokeWidth: 0,
            radius: 0,
            opacity: 1,
          },
          zIndex: 20,
          bookableId: null,
        },
        {
          id: "n_emoji_kitchen",
          kind: "emoji",
          role: "decor",
          label: "🍳",
          frame: { x: 1120, y: 80, w: 48, h: 48 },
          style: {
            fill: null,
            stroke: "transparent",
            strokeWidth: 0,
            radius: 0,
            opacity: 1,
          },
          zIndex: 20,
          bookableId: null,
        },
        {
          id: "n_divider",
          kind: "line",
          role: "decor",
          label: null,
          points: [
            { x: 80, y: 190 },
            { x: 1200, y: 190 },
          ],
          style: {
            fill: null,
            stroke: "#DDDDDD",
            strokeWidth: 3,
            radius: 0,
            opacity: 1,
          },
          zIndex: 2,
          bookableId: null,
        },
        {
          id: "n_table_1",
          kind: "rect",
          role: "bookable",
          label: "1",
          frame: { x: 120, y: 240, w: 200, h: 160 },
          groupId: "g_table_1",
          style: {
            fill: "#FFA39E",
            stroke: "#B54B45",
            strokeWidth: 2,
            radius: 14,
            opacity: 1,
          },
          zIndex: 10,
          bookableId: "bk_table_1",
        },
        {
          id: "n_chair_1a",
          kind: "ellipse",
          role: "decor",
          label: null,
          frame: { x: 150, y: 210, w: 44, h: 44 },
          groupId: "g_table_1",
          style: {
            fill: "#FDF08B",
            stroke: "#9A7B00",
            strokeWidth: 2,
            radius: 999,
            opacity: 1,
          },
          zIndex: 11,
          bookableId: null,
        },
        {
          id: "n_chair_1b",
          kind: "ellipse",
          role: "decor",
          label: null,
          frame: { x: 246, y: 210, w: 44, h: 44 },
          groupId: "g_table_1",
          style: {
            fill: "#FDF08B",
            stroke: "#9A7B00",
            strokeWidth: 2,
            radius: 999,
            opacity: 1,
          },
          zIndex: 11,
          bookableId: null,
        },
        {
          id: "n_table_oval",
          kind: "ellipse",
          role: "bookable",
          label: "VIP",
          frame: { x: 400, y: 230, w: 240, h: 180 },
          rotation: 8,
          style: {
            fill: "#EDE9FB",
            stroke: "#5C4FA8",
            strokeWidth: 2,
            radius: 999,
            opacity: 1,
          },
          zIndex: 10,
          bookableId: "bk_vip",
        },
        {
          id: "n_zone_lounge",
          kind: "polygon",
          role: "bookable",
          label: "Лаунж",
          points: [
            { x: 720, y: 230 },
            { x: 980, y: 230 },
            { x: 1040, y: 360 },
            { x: 900, y: 430 },
            { x: 700, y: 360 },
          ],
          style: {
            fill: "#E3F0FC",
            stroke: "#5B9BD5",
            strokeWidth: 2,
            radius: 0,
            opacity: 0.92,
          },
          zIndex: 9,
          bookableId: "bk_lounge",
        },
        {
          id: "n_stage",
          kind: "rect",
          role: "decor",
          label: "Сцена",
          frame: { x: 120, y: 520, w: 360, h: 100 },
          style: {
            fill: "#1A1D1E",
            stroke: "#6A6A6A",
            strokeWidth: 2,
            radius: 10,
            opacity: 1,
          },
          zIndex: 5,
          bookableId: null,
        },
        {
          id: "n_donut_column",
          kind: "path",
          role: "decor",
          label: "Колонна",
          points: [
            { x: 580, y: 520 },
            { x: 700, y: 520 },
            { x: 700, y: 640 },
            { x: 580, y: 640 },
          ],
          holes: [
            [
              { x: 610, y: 550 },
              { x: 670, y: 550 },
              { x: 670, y: 610 },
              { x: 610, y: 610 },
            ],
          ],
          style: {
            fill: "#E8E8E8",
            stroke: "#CCCCCC",
            strokeWidth: 2,
            radius: 0,
            opacity: 1,
          },
          zIndex: 6,
          bookableId: null,
        },
        {
          id: "n_path_wall",
          kind: "path",
          role: "decor",
          label: null,
          points: [
            { x: 780, y: 520 },
            { x: 1100, y: 520 },
            { x: 1100, y: 700 },
            { x: 780, y: 700 },
            { x: 780, y: 520 },
          ],
          style: {
            fill: null,
            stroke: "#B54B45",
            strokeWidth: 4,
            radius: 0,
            opacity: 1,
          },
          zIndex: 4,
          bookableId: null,
        },
        {
          id: "n_booth",
          kind: "rect",
          role: "bookable",
          label: "Кабина",
          frame: { x: 820, y: 560, w: 220, h: 100 },
          style: {
            fill: "#C5FEB7",
            stroke: "#3D8B40",
            strokeWidth: 2,
            radius: 18,
            opacity: 1,
          },
          zIndex: 10,
          bookableId: "bk_booth",
        },
        {
          id: "n_emoji_wc",
          kind: "emoji",
          role: "decor",
          label: "🚻",
          frame: { x: 1120, y: 720, w: 44, h: 44 },
          style: {
            fill: null,
            stroke: "transparent",
            strokeWidth: 0,
            radius: 0,
            opacity: 1,
          },
          zIndex: 20,
          bookableId: null,
        },
        {
          id: "n_hint",
          kind: "text",
          role: "decor",
          label: "decor ≠ клик · bookable = бронь",
          frame: { x: 120, y: 760, w: 420, h: 32 },
          style: {
            fill: null,
            stroke: "transparent",
            strokeWidth: 0,
            radius: 0,
            opacity: 1,
          },
          zIndex: 21,
          bookableId: null,
        },
      ],
    },
    {
      id: "plan_full_floor_2",
      floorKey: "floor_2",
      label: "2 этаж · терраса",
      version: 1,
      status: "draft",
      canvas: { width: 1280, height: 860, background: "#E3F0FC" },
      nodes: [
        {
          id: "n2_title",
          kind: "text",
          role: "decor",
          label: "Терраса",
          frame: { x: 80, y: 60, w: 280, h: 40 },
          style: {
            fill: null,
            stroke: "transparent",
            strokeWidth: 0,
            radius: 0,
            opacity: 1,
          },
          zIndex: 20,
          bookableId: null,
        },
        {
          id: "n2_plant",
          kind: "emoji",
          role: "decor",
          label: "🪴",
          frame: { x: 80, y: 120, w: 52, h: 52 },
          style: {
            fill: null,
            stroke: "transparent",
            strokeWidth: 0,
            radius: 0,
            opacity: 1,
          },
          zIndex: 15,
          bookableId: null,
        },
        {
          id: "n2_table_a",
          kind: "ellipse",
          role: "bookable",
          label: "T1",
          frame: { x: 200, y: 200, w: 180, h: 180 },
          style: {
            fill: "#FFA39E",
            stroke: "#B54B45",
            strokeWidth: 2,
            radius: 999,
            opacity: 1,
          },
          zIndex: 10,
          bookableId: "bk_terrace_1",
        },
        {
          id: "n2_table_b",
          kind: "ellipse",
          role: "bookable",
          label: "T2",
          frame: { x: 480, y: 200, w: 180, h: 180 },
          style: {
            fill: "#FFA39E",
            stroke: "#B54B45",
            strokeWidth: 2,
            radius: 999,
            opacity: 1,
          },
          zIndex: 10,
          bookableId: "bk_terrace_2",
        },
        {
          id: "n2_rail",
          kind: "line",
          role: "decor",
          label: null,
          points: [
            { x: 80, y: 480 },
            { x: 1200, y: 480 },
          ],
          style: {
            fill: null,
            stroke: "#5B9BD5",
            strokeWidth: 4,
            radius: 0,
            opacity: 1,
          },
          zIndex: 3,
          bookableId: null,
        },
      ],
    },
  ],
};

/** Строка для textarea / AI (pretty). */
export function planFullExampleJson(): string {
  return JSON.stringify(PLAN_FULL_EXAMPLE_BUILDING, null, 2);
}

/** Краткая шпаргалка для промпта AI (рядом с примером). */
export const PLAN_JSON_AI_HINT = `Схема Clover — JSON здания.
Обязательно: version:1, floors[], activeFloorKey.
Этаж: id, floorKey, label, version, status ("draft"|"published"), canvas{width,height,background}, nodes[].
Узел kind: rect|ellipse|line|polygon|path|emoji|text.
role: decor (не кликается) | bookable (бронь; нужен bookableId).
frame {x,y,w,h} — для rect/ellipse/emoji/text.
points[] — для line/polygon/path.
holes[][] — дыры у path (опционально).
rotation — градусы (опц.).
groupId — одна группа двигается вместе (стол+стулья).
style: fill (null ок), stroke, strokeWidth, radius, opacity.
zIndex: число.
Не клади inventory/занятость внутрь nodes — это отдельно на клиенте.
Координаты в px холста; не выходи за canvas.`;
