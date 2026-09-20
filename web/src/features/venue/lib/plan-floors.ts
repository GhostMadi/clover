import {
  createEmptyPlan,
  newNodeId,
  type PlanDocument,
} from "@/features/venue/lib/plan-editor-types";

/** Черновик здания: несколько этажей, один активный. */
export type VenueBuildingDraft = {
  version: 1;
  floors: PlanDocument[];
  activeFloorKey: string;
};

export function buildingFromPlan(plan: PlanDocument): VenueBuildingDraft {
  const safe = {
    ...plan,
    floorKey: plan.floorKey || "floor_1",
    nodes: Array.isArray(plan.nodes) ? plan.nodes : [],
  };
  return {
    version: 1,
    floors: [safe],
    activeFloorKey: safe.floorKey,
  };
}

export function ensureBuilding(raw: unknown): VenueBuildingDraft | null {
  if (!raw || typeof raw !== "object") return null;
  const obj = raw as Record<string, unknown>;

  // Новый формат
  if (Array.isArray(obj.floors) && typeof obj.activeFloorKey === "string") {
    const floors = (obj.floors as PlanDocument[]).filter(
      (f) => f && Array.isArray(f.nodes) && f.canvas,
    );
    if (!floors.length) return null;
    const active =
      floors.find((f) => f.floorKey === obj.activeFloorKey)?.floorKey ?? floors[0]!.floorKey;
    return { version: 1, floors, activeFloorKey: active };
  }

  // Legacy: один план
  if (Array.isArray(obj.nodes) && obj.canvas) {
    return buildingFromPlan(obj as unknown as PlanDocument);
  }

  return null;
}

export function activeFloor(building: VenueBuildingDraft): PlanDocument {
  return (
    building.floors.find((f) => f.floorKey === building.activeFloorKey) ??
    building.floors[0]!
  );
}

export function upsertFloor(
  building: VenueBuildingDraft,
  plan: PlanDocument,
): VenueBuildingDraft {
  const floors = building.floors.map((f) =>
    f.floorKey === plan.floorKey ? plan : f,
  );
  if (!floors.some((f) => f.floorKey === plan.floorKey)) {
    floors.push(plan);
  }
  return { ...building, floors };
}

export function createNextFloor(existing: PlanDocument[]): PlanDocument {
  const n = existing.length + 1;
  const plan = createEmptyPlan();
  plan.id = `plan_${newNodeId("floor")}`;
  plan.floorKey = `floor_${n}`;
  plan.label = `${n} этаж`;
  plan.canvas = {
    width: 1280,
    height: 860,
    background: existing[0]?.canvas.background ?? "#F7F7F8",
  };
  return plan;
}

export function sortFloors(floors: PlanDocument[]): PlanDocument[] {
  return [...floors].sort((a, b) => a.floorKey.localeCompare(b.floorKey, "en"));
}
