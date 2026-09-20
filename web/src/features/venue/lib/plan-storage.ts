import type { PlanDocument } from "@/features/venue/lib/plan-editor-types";
import {
  ensureBuilding,
  type VenueBuildingDraft,
} from "@/features/venue/lib/plan-floors";

const keyFor = (venueId: string) => `clover.venue.plan.draft.${venueId}`;

export function saveBuildingDraft(venueId: string, building: VenueBuildingDraft): void {
  try {
    localStorage.setItem(keyFor(venueId), JSON.stringify(building));
  } catch {
    /* quota / private mode */
  }
}

/** @deprecated prefer saveBuildingDraft — оставлен для совместимости вызовов. */
export function savePlanDraft(venueId: string, plan: PlanDocument): void {
  saveBuildingDraft(venueId, {
    version: 1,
    floors: [plan],
    activeFloorKey: plan.floorKey || "floor_1",
  });
}

export function loadBuildingDraft(venueId: string): VenueBuildingDraft | null {
  try {
    const raw = localStorage.getItem(keyFor(venueId));
    if (!raw) return null;
    return ensureBuilding(JSON.parse(raw));
  } catch {
    return null;
  }
}

/** Legacy: один этаж из черновика. */
export function loadPlanDraft(venueId: string): PlanDocument | null {
  const b = loadBuildingDraft(venueId);
  if (!b) return null;
  return b.floors.find((f) => f.floorKey === b.activeFloorKey) ?? b.floors[0] ?? null;
}

export function clearPlanDraft(venueId: string): void {
  try {
    localStorage.removeItem(keyFor(venueId));
  } catch {
    /* ignore */
  }
}

export function downloadPlanJson(
  data: PlanDocument | VenueBuildingDraft,
  filename = "venue-plan.json",
): void {
  const blob = new Blob([JSON.stringify(data, null, 2)], { type: "application/json" });
  const url = URL.createObjectURL(blob);
  const a = document.createElement("a");
  a.href = url;
  a.download = filename;
  a.click();
  URL.revokeObjectURL(url);
}

export async function readPlanJsonFile(
  file: File,
): Promise<VenueBuildingDraft | PlanDocument | null> {
  try {
    const text = await file.text();
    const parsed = JSON.parse(text) as unknown;
    const building = ensureBuilding(parsed);
    if (building) return building;
    return null;
  } catch {
    return null;
  }
}
