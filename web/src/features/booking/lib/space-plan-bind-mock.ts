/**
 * Mock: схема точки Записи + bind emoji → услуга (+ мастер).
 * Ценники только на kind===emoji. Бэка нет.
 * docs/business/space-plan-emoji-pricing.md
 */

import { listSpacePlans, type SpacePlanMeta } from "@/features/resources/lib/space-plans-mock";
import { loadBuildingDraft } from "@/features/venue/lib/plan-storage";
import type { PlanNode } from "@/features/venue/lib/plan-editor-types";

const bindKey = (pointId: string) => `clover.booking.space_bind.v1.${pointId}`;

export type EmojiServiceBind = {
  nodeId: string;
  /** emoji char / label */
  emoji: string;
  serviceId: string;
  serviceTitle: string;
  /** цена услуги, ₸ */
  priceKzt: number;
  staffId: string | null;
  staffName: string | null;
};

export type PointSpaceBindState = {
  spacePlanId: string | null;
  binds: EmojiServiceBind[];
};

export function readPointSpaceBind(pointId: string): PointSpaceBindState {
  if (typeof window === "undefined") {
    return { spacePlanId: null, binds: [] };
  }
  try {
    const raw = localStorage.getItem(bindKey(pointId));
    if (!raw) return { spacePlanId: null, binds: [] };
    const parsed = JSON.parse(raw) as PointSpaceBindState;
    return {
      spacePlanId: parsed.spacePlanId ?? null,
      binds: Array.isArray(parsed.binds) ? parsed.binds : [],
    };
  } catch {
    return { spacePlanId: null, binds: [] };
  }
}

export function writePointSpaceBind(pointId: string, state: PointSpaceBindState): void {
  try {
    localStorage.setItem(bindKey(pointId), JSON.stringify(state));
  } catch {
    /* ignore */
  }
}

export function setPointSpacePlan(pointId: string, spacePlanId: string | null): PointSpaceBindState {
  const prev = readPointSpaceBind(pointId);
  const next: PointSpaceBindState = {
    spacePlanId,
    binds: spacePlanId === prev.spacePlanId ? prev.binds : [],
  };
  writePointSpaceBind(pointId, next);
  return next;
}

export function upsertEmojiBind(pointId: string, bind: EmojiServiceBind): PointSpaceBindState {
  const prev = readPointSpaceBind(pointId);
  const binds = prev.binds.filter((b) => b.nodeId !== bind.nodeId);
  binds.push(bind);
  const next = { ...prev, binds };
  writePointSpaceBind(pointId, next);
  return next;
}

/** Одно назначение на несколько nodeId (одинаковые emoji). */
export function upsertEmojiBinds(pointId: string, bindsIn: EmojiServiceBind[]): PointSpaceBindState {
  const prev = readPointSpaceBind(pointId);
  const ids = new Set(bindsIn.map((b) => b.nodeId));
  const binds = prev.binds.filter((b) => !ids.has(b.nodeId));
  binds.push(...bindsIn);
  const next = { ...prev, binds };
  writePointSpaceBind(pointId, next);
  return next;
}

export function clearEmojiBinds(pointId: string, nodeIds: string[]): PointSpaceBindState {
  const ids = new Set(nodeIds);
  const prev = readPointSpaceBind(pointId);
  const next = { ...prev, binds: prev.binds.filter((b) => !ids.has(b.nodeId)) };
  writePointSpaceBind(pointId, next);
  return next;
}

export function clearEmojiBind(pointId: string, nodeId: string): PointSpaceBindState {
  const prev = readPointSpaceBind(pointId);
  const next = { ...prev, binds: prev.binds.filter((b) => b.nodeId !== nodeId) };
  writePointSpaceBind(pointId, next);
  return next;
}

/** Emoji-узлы со всех этажей привязанной схемы. */
export function listEmojiNodesForPoint(pointId: string): {
  plan: SpacePlanMeta | null;
  emojis: Array<{
    nodeId: string;
    emoji: string;
    floorLabel: string;
    groupId: string | null;
  }>;
} {
  const { spacePlanId } = readPointSpaceBind(pointId);
  if (!spacePlanId) return { plan: null, emojis: [] };
  const plan = listSpacePlans().find((p) => p.id === spacePlanId) ?? null;
  const building = loadBuildingDraft(spacePlanId);
  if (!building) return { plan, emojis: [] };

  const emojis: Array<{
    nodeId: string;
    emoji: string;
    floorLabel: string;
    groupId: string | null;
  }> = [];
  for (const floor of building.floors) {
    for (const n of floor.nodes) {
      if (!isPriceableEmoji(n)) continue;
      emojis.push({
        nodeId: n.id,
        emoji: (n.label && n.label.trim()) || "📍",
        floorLabel: floor.label || floor.floorKey,
        groupId: n.groupId ?? null,
      });
    }
  }
  return { plan, emojis };
}

export function isPriceableEmoji(node: PlanNode): boolean {
  return node.kind === "emoji" && node.role === "bookable";
}

/** Мок-каталог услуг/мастеров, если API ещё пустой. */
export const MOCK_BIND_SERVICES = [
  { id: "svc_cut", title: "Стрижка", priceKzt: 5000 },
  { id: "svc_color", title: "Окрашивание", priceKzt: 18000 },
  { id: "svc_manicure", title: "Маникюр", priceKzt: 8000 },
] as const;

export const MOCK_BIND_STAFF = [
  { id: "st_aigerim", name: "Айгерим", serviceIds: ["svc_cut", "svc_color"] },
  { id: "st_daniyar", name: "Данияр", serviceIds: ["svc_cut"] },
  { id: "st_sabina", name: "Сабина", serviceIds: ["svc_manicure", "svc_color"] },
] as const;
