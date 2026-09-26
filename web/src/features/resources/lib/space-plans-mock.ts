/**
 * Mock: схемы пространства в Ресурсах (localStorage).
 * Процесс: docs/business/space-plan-resources.md
 * Геометрия этажей — через clover.venue.plan.draft.{id} (тот же редактор).
 */

import { createCafeBuilding, createCinemaStarterPlan } from "@/features/venue/lib/plan-editor-export";
import { PLAN_CRAZY_EMOJI_BUILDING } from "@/features/venue/lib/plan-crazy-emoji-example";
import { createEmptyPlan } from "@/features/venue/lib/plan-editor-types";
import type { VenueBuildingDraft } from "@/features/venue/lib/plan-floors";
import { saveBuildingDraft } from "@/features/venue/lib/plan-storage";

const META_KEY = "clover.resources.space_plans.v1";

export type SpacePlanStatus = "draft" | "published";

export type SpacePlanMeta = {
  id: string;
  title: string;
  status: SpacePlanStatus;
  /** Подсказка в списке (не источник правды этажей). */
  floorCount: number;
  updatedAt: string;
  /** Стартовый шаблон при первом открытии редактора. */
  starter?: "empty" | "cafe" | "cinema" | "crazy_emoji";
};

function readRaw(): SpacePlanMeta[] {
  if (typeof window === "undefined") return [];
  try {
    const raw = localStorage.getItem(META_KEY);
    if (!raw) return [];
    const parsed = JSON.parse(raw) as unknown;
    if (!Array.isArray(parsed)) return [];
    return parsed.filter(
      (row): row is SpacePlanMeta =>
        !!row &&
        typeof row === "object" &&
        typeof (row as SpacePlanMeta).id === "string" &&
        typeof (row as SpacePlanMeta).title === "string",
    );
  } catch {
    return [];
  }
}

function writeRaw(items: SpacePlanMeta[]) {
  try {
    localStorage.setItem(META_KEY, JSON.stringify(items));
  } catch {
    /* quota */
  }
}

function newId() {
  return `sp_${Date.now().toString(36)}_${Math.random().toString(36).slice(2, 7)}`;
}

/** Первый заход — демо-схемы (мета + черновик геометрии). */
export function ensureSpacePlansSeeded(): SpacePlanMeta[] {
  const existing = readRaw();
  if (existing.length > 0) return existing;

  const now = new Date().toISOString();
  const seed: SpacePlanMeta[] = [
    {
      id: "sp_demo_cafe",
      title: "Зал кафе (демо)",
      status: "published",
      floorCount: 2,
      updatedAt: now,
      starter: "cafe",
    },
    {
      id: "sp_demo_cinema",
      title: "Кинозал (демо)",
      status: "draft",
      floorCount: 1,
      updatedAt: now,
      starter: "cinema",
    },
  ];
  writeRaw(seed);
  ensureGeometry(seed[0]!);
  ensureGeometry(seed[1]!);
  return seed;
}

function ensureGeometry(meta: SpacePlanMeta) {
  if (typeof window === "undefined") return;
  try {
    const key = `clover.venue.plan.draft.${meta.id}`;
    if (localStorage.getItem(key)) return;
  } catch {
    /* ignore */
  }
  const building = buildingForStarter(meta.starter ?? "empty");
  saveBuildingDraft(meta.id, building);
}

/** Гарантировать draft геометрии (для превью / bind на точке). */
export function ensureSpacePlanDraft(id: string): void {
  const meta = readRaw().find((p) => p.id === id) ?? getSpacePlan(id);
  if (meta) ensureGeometry(meta);
}

function buildingForStarter(starter: SpacePlanMeta["starter"]): VenueBuildingDraft {
  if (starter === "cafe") return createCafeBuilding();
  if (starter === "crazy_emoji") return PLAN_CRAZY_EMOJI_BUILDING;
  if (starter === "cinema") {
    const plan = createCinemaStarterPlan();
    return {
      version: 1,
      floors: [plan],
      activeFloorKey: plan.floorKey || "floor_1",
    };
  }
  const empty = createEmptyPlan();
  return {
    version: 1,
    floors: [empty],
    activeFloorKey: empty.floorKey || "floor_1",
  };
}

export function listSpacePlans(): SpacePlanMeta[] {
  return ensureSpacePlansSeeded().slice().sort((a, b) => b.updatedAt.localeCompare(a.updatedAt));
}

export function getSpacePlan(id: string): SpacePlanMeta | null {
  return listSpacePlans().find((p) => p.id === id) ?? null;
}

export function createSpacePlan(input?: {
  title?: string;
  starter?: SpacePlanMeta["starter"];
}): SpacePlanMeta {
  ensureSpacePlansSeeded();
  const title = (input?.title ?? "").trim() || "Новая схема";
  const starter = input?.starter ?? "empty";
  const meta: SpacePlanMeta = {
    id: newId(),
    title,
    status: "draft",
    floorCount: starter === "cafe" || starter === "crazy_emoji" ? 2 : 1,
    updatedAt: new Date().toISOString(),
    starter,
  };
  const next = [meta, ...readRaw()];
  writeRaw(next);
  ensureGeometry(meta);
  return meta;
}

export function renameSpacePlan(id: string, title: string): SpacePlanMeta | null {
  const t = title.trim();
  if (!t) return null;
  const items = readRaw();
  const idx = items.findIndex((p) => p.id === id);
  if (idx < 0) return null;
  const updated: SpacePlanMeta = {
    ...items[idx]!,
    title: t,
    updatedAt: new Date().toISOString(),
  };
  items[idx] = updated;
  writeRaw(items);
  return updated;
}

export function setSpacePlanStatus(id: string, status: SpacePlanStatus): SpacePlanMeta | null {
  const items = readRaw();
  const idx = items.findIndex((p) => p.id === id);
  if (idx < 0) return null;
  const updated: SpacePlanMeta = {
    ...items[idx]!,
    status,
    updatedAt: new Date().toISOString(),
  };
  items[idx] = updated;
  writeRaw(items);
  return updated;
}

export function touchSpacePlan(id: string, floorCount?: number): void {
  const items = readRaw();
  const idx = items.findIndex((p) => p.id === id);
  if (idx < 0) return;
  items[idx] = {
    ...items[idx]!,
    floorCount: floorCount ?? items[idx]!.floorCount,
    updatedAt: new Date().toISOString(),
  };
  writeRaw(items);
}

export function deleteSpacePlan(id: string): boolean {
  const before = readRaw();
  const items = before.filter((p) => p.id !== id);
  if (items.length === before.length) return false;
  writeRaw(items);
  try {
    localStorage.removeItem(`clover.venue.plan.draft.${id}`);
  } catch {
    /* ignore */
  }
  return true;
}

export function spacePlanStatusLabel(status: SpacePlanStatus): string {
  return status === "published" ? "Опубликована" : "Черновик";
}
