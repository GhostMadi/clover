import polygonClipping from "polygon-clipping";
import {
  defaultStyle,
  newNodeId,
  type PlanNode,
  type PlanPoint,
} from "@/features/venue/lib/plan-editor-types";

type Pair = [number, number];
type Ring = Pair[];
type Poly = Ring[];

const ELLIPSE_SEGMENTS = 48;

function closeRing(ring: Ring): Ring {
  if (ring.length < 3) return ring;
  const first = ring[0]!;
  const last = ring[ring.length - 1]!;
  if (first[0] === last[0] && first[1] === last[1]) return ring;
  return [...ring, [first[0], first[1]]];
}

function pointsToRing(points: PlanPoint[]): Ring {
  return closeRing(points.map((p) => [p.x, p.y] as Pair));
}

function ringToPoints(ring: Ring): PlanPoint[] {
  const pts = ring.map(([x, y]) => ({ x, y }));
  if (pts.length > 1) {
    const a = pts[0]!;
    const b = pts[pts.length - 1]!;
    if (Math.hypot(a.x - b.x, a.y - b.y) < 0.01) pts.pop();
  }
  return pts;
}

function rectRing(frame: { x: number; y: number; w: number; h: number }, radius: number): Ring {
  const { x, y, w, h } = frame;
  const r = Math.max(0, Math.min(radius, Math.min(w, h) / 2));
  if (r < 0.5) {
    return closeRing([
      [x, y],
      [x + w, y],
      [x + w, y + h],
      [x, y + h],
    ]);
  }
  // Упрощённые скругления — по 4 точки на угол
  const k = 0.5523;
  const pts: Pair[] = [];
  const arc = (cx: number, cy: number, from: number, to: number) => {
    const steps = 6;
    for (let i = 0; i <= steps; i++) {
      const t = from + ((to - from) * i) / steps;
      pts.push([cx + Math.cos(t) * r, cy + Math.sin(t) * r]);
    }
  };
  arc(x + w - r, y + r, -Math.PI / 2, 0);
  arc(x + w - r, y + h - r, 0, Math.PI / 2);
  arc(x + r, y + h - r, Math.PI / 2, Math.PI);
  arc(x + r, y + r, Math.PI, (3 * Math.PI) / 2);
  void k;
  return closeRing(pts);
}

function ellipseRing(frame: { x: number; y: number; w: number; h: number }): Ring {
  const cx = frame.x + frame.w / 2;
  const cy = frame.y + frame.h / 2;
  const rx = Math.max(1, frame.w / 2);
  const ry = Math.max(1, frame.h / 2);
  const pts: Pair[] = [];
  for (let i = 0; i < ELLIPSE_SEGMENTS; i++) {
    const t = (i / ELLIPSE_SEGMENTS) * Math.PI * 2;
    pts.push([cx + Math.cos(t) * rx, cy + Math.sin(t) * ry]);
  }
  return closeRing(pts);
}

/** Замкнутая фигура → полигон для булевых операций. */
export function nodeToPolygon(node: PlanNode): Poly | null {
  if (node.kind === "rect" && node.frame) {
    return [rectRing(node.frame, node.style.radius)];
  }
  if (node.kind === "ellipse" && node.frame) {
    return [ellipseRing(node.frame)];
  }
  if (node.kind === "polygon" && node.points && node.points.length >= 3) {
    const outer = pointsToRing(node.points);
    const holes = (node.holes ?? []).filter((h) => h.length >= 3).map(pointsToRing);
    return [outer, ...holes];
  }
  return null;
}

export function canBooleanMerge(node: PlanNode): boolean {
  return nodeToPolygon(node) !== null;
}

function boundsOfPoints(points: PlanPoint[]): { x: number; y: number; w: number; h: number } {
  const xs = points.map((p) => p.x);
  const ys = points.map((p) => p.y);
  const minX = Math.min(...xs);
  const maxX = Math.max(...xs);
  const minY = Math.min(...ys);
  const maxY = Math.max(...ys);
  return { x: minX, y: minY, w: Math.max(1, maxX - minX), h: Math.max(1, maxY - minY) };
}

function polyToNodes(
  multi: Poly[],
  styleBase: PlanNode,
  role: PlanNode["role"],
  bookableId: string | null,
): PlanNode[] {
  const out: PlanNode[] = [];
  for (const poly of multi) {
    const [outer, ...holes] = poly;
    if (!outer || outer.length < 3) continue;
    const points = ringToPoints(outer);
    const holePts = holes.map(ringToPoints).filter((h) => h.length >= 3);
    out.push({
      id: newNodeId(),
      kind: "polygon",
      role,
      label: styleBase.label,
      points,
      holes: holePts.length ? holePts : undefined,
      frame: boundsOfPoints(points),
      style: defaultStyle({
        fill: styleBase.style.fill,
        stroke: styleBase.style.stroke,
        strokeWidth: styleBase.style.strokeWidth,
        radius: 0,
        opacity: styleBase.style.opacity,
      }),
      zIndex: styleBase.zIndex,
      bookableId,
    });
  }
  return out;
}

/** Объединить замкнутые фигуры — внутренние рёбра исчезают. */
export function unionNodes(nodes: PlanNode[]): PlanNode[] | null {
  const polys = nodes.map(nodeToPolygon);
  if (polys.some((p) => !p) || polys.length < 2) return null;
  try {
    const result = polygonClipping.union(polys[0]!, ...(polys.slice(1) as Poly[]));
    if (!result.length) return null;
    const base = nodes[0]!;
    const role = nodes.some((n) => n.role === "bookable") ? "bookable" : "decor";
    const bookableId =
      role === "bookable"
        ? (nodes.find((n) => n.bookableId)?.bookableId ?? newNodeId("bk"))
        : null;
    return polyToNodes(result, base, role, bookableId);
  } catch {
    return null;
  }
}

/** Вычесть: первая фигура минус остальные. */
export function subtractNodes(nodes: PlanNode[]): PlanNode[] | null {
  const polys = nodes.map(nodeToPolygon);
  if (polys.some((p) => !p) || polys.length < 2) return null;
  try {
    const result = polygonClipping.difference(polys[0]!, ...(polys.slice(1) as Poly[]));
    if (!result.length) return null;
    const base = nodes[0]!;
    return polyToNodes(result, base, base.role, base.bookableId);
  } catch {
    return null;
  }
}

export function nodeBounds(node: PlanNode): { x: number; y: number; w: number; h: number } | null {
  if (node.frame) return node.frame;
  if (node.points?.length) return boundsOfPoints(node.points);
  return null;
}

export function boundsIntersect(
  a: { x: number; y: number; w: number; h: number },
  b: { x: number; y: number; w: number; h: number },
): boolean {
  return a.x < b.x + b.w && a.x + a.w > b.x && a.y < b.y + b.h && a.y + a.h > b.y;
}

export function ringsToPathD(outer: PlanPoint[], holes?: PlanPoint[][]): string {
  const ring = (pts: PlanPoint[]) =>
    pts.map((p, i) => `${i === 0 ? "M" : "L"}${p.x} ${p.y}`).join(" ") + " Z";
  return [ring(outer), ...(holes ?? []).map(ring)].join(" ");
}
