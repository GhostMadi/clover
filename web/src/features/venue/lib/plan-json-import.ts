import type { PlanDocument, PlanNode, PlanNodeKind, PlanNodeRole } from "@/features/venue/lib/plan-editor-types";
import { createEmptyPlan, defaultStyle } from "@/features/venue/lib/plan-editor-types";
import {
  buildingFromPlan,
  ensureBuilding,
  type VenueBuildingDraft,
} from "@/features/venue/lib/plan-floors";

/**
 * Принимает JSON из редактора, файла, AI или product-примера
 * (`venue-plan.example.json` / snake_case) → черновик здания.
 */
export function parsePlanJsonText(text: string): VenueBuildingDraft | null {
  try {
    const parsed = JSON.parse(text) as unknown;
    return normalizeToBuilding(parsed);
  } catch {
    return null;
  }
}

export function normalizeToBuilding(raw: unknown): VenueBuildingDraft | null {
  if (!raw || typeof raw !== "object") return null;

  // Уже editor-формат (camelCase building / один план)
  const direct = ensureBuilding(raw);
  if (direct) return direct;

  const obj = raw as Record<string, unknown>;

  // Product envelope: { schema_version, plan, bookables? }
  if (obj.plan && typeof obj.plan === "object") {
    const plan = coercePlan(obj.plan);
    if (plan) return buildingFromPlan(plan);
  }

  // { floors: [snake|camel plans], active_floor_key | activeFloorKey }
  if (Array.isArray(obj.floors)) {
    const floors = (obj.floors as unknown[])
      .map(coercePlan)
      .filter((f): f is PlanDocument => !!f);
    if (!floors.length) return null;
    const activeKey =
      (typeof obj.activeFloorKey === "string" && obj.activeFloorKey) ||
      (typeof obj.active_floor_key === "string" && obj.active_floor_key) ||
      floors[0]!.floorKey;
    return {
      version: 1,
      floors,
      activeFloorKey: floors.find((f) => f.floorKey === activeKey)?.floorKey ?? floors[0]!.floorKey,
    };
  }

  // Один план в snake_case
  const one = coercePlan(obj);
  if (one) return buildingFromPlan(one);

  return null;
}

function str(v: unknown, fallback = ""): string {
  return typeof v === "string" ? v : fallback;
}

function num(v: unknown, fallback: number): number {
  return typeof v === "number" && Number.isFinite(v) ? v : fallback;
}

function coercePlan(raw: unknown): PlanDocument | null {
  if (!raw || typeof raw !== "object") return null;
  const o = raw as Record<string, unknown>;
  const canvasRaw = o.canvas;
  if (!canvasRaw || typeof canvasRaw !== "object") return null;
  const c = canvasRaw as Record<string, unknown>;
  const nodesRaw = o.nodes;
  if (!Array.isArray(nodesRaw)) return null;

  const base = createEmptyPlan();
  const nodes = nodesRaw.map(coerceNode).filter((n): n is PlanNode => !!n);

  return {
    id: str(o.id, base.id),
    floorKey: str(o.floorKey || o.floor_key, base.floorKey),
    label: str(o.label, base.label),
    version: num(o.version, 1),
    status: o.status === "published" ? "published" : "draft",
    canvas: {
      width: num(c.width, 1280),
      height: num(c.height, 860),
      background: str(c.background, "#F7F7F8"),
    },
    nodes,
  };
}

const KINDS = new Set<PlanNodeKind>([
  "rect",
  "ellipse",
  "line",
  "polygon",
  "path",
  "emoji",
  "text",
]);

function coerceNode(raw: unknown): PlanNode | null {
  if (!raw || typeof raw !== "object") return null;
  const o = raw as Record<string, unknown>;
  const kind = str(o.kind) as PlanNodeKind;
  if (!KINDS.has(kind)) return null;
  const role: PlanNodeRole = o.role === "bookable" ? "bookable" : "decor";
  const styleRaw =
    o.style && typeof o.style === "object" ? (o.style as Record<string, unknown>) : {};

  const frame =
    o.frame && typeof o.frame === "object"
      ? {
          x: num((o.frame as Record<string, unknown>).x, 0),
          y: num((o.frame as Record<string, unknown>).y, 0),
          w: num((o.frame as Record<string, unknown>).w, 40),
          h: num((o.frame as Record<string, unknown>).h, 40),
        }
      : undefined;

  return {
    id: str(o.id, `n_${Math.random().toString(36).slice(2, 8)}`),
    kind,
    role,
    label: o.label == null ? null : str(o.label),
    frame,
    points: Array.isArray(o.points) ? (o.points as PlanNode["points"]) : undefined,
    holes: Array.isArray(o.holes) ? (o.holes as PlanNode["holes"]) : undefined,
    rotation: typeof o.rotation === "number" ? o.rotation : undefined,
    groupId:
      o.groupId != null
        ? str(o.groupId)
        : o.group_id != null
          ? str(o.group_id)
          : null,
    style: defaultStyle({
      fill: styleRaw.fill === null ? null : str(styleRaw.fill, "#E8E8E8"),
      stroke: str(styleRaw.stroke, "#CCCCCC"),
      strokeWidth: num(styleRaw.strokeWidth ?? styleRaw.stroke_width, 2),
      radius: num(styleRaw.radius, 12),
      opacity: num(styleRaw.opacity, 1),
    }),
    zIndex: num(o.zIndex ?? o.z_index, role === "bookable" ? 10 : 2),
    bookableId:
      o.bookableId === null || o.bookable_id === null
        ? null
        : o.bookableId != null
          ? str(o.bookableId)
          : o.bookable_id != null
            ? str(o.bookable_id)
            : null,
  };
}
