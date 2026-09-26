import {
  PLAN_GRID,
  newNodeId,
  type PlanDocument,
  type PlanNode,
  type PlanPoint,
} from "@/features/venue/lib/plan-editor-types";

export function snapValue(n: number, grid = PLAN_GRID, enabled = true): number {
  if (!enabled) return n;
  return Math.round(n / grid) * grid;
}

export function snapPoint(p: PlanPoint, enabled = true, grid = PLAN_GRID): PlanPoint {
  return { x: snapValue(p.x, grid, enabled), y: snapValue(p.y, grid, enabled) };
}

export function nodeCenter(node: PlanNode): PlanPoint {
  if (node.frame) {
    return {
      x: node.frame.x + node.frame.w / 2,
      y: node.frame.y + node.frame.h / 2,
    };
  }
  if (node.points?.length) {
    const xs = node.points.map((p) => p.x);
    const ys = node.points.map((p) => p.y);
    return {
      x: (Math.min(...xs) + Math.max(...xs)) / 2,
      y: (Math.min(...ys) + Math.max(...ys)) / 2,
    };
  }
  return { x: 0, y: 0 };
}

/** Все id, которые двигаются вместе с выделением (группы). */
export function expandSelectionWithGroups(
  nodes: PlanNode[],
  selectedIds: string[],
): string[] {
  const byId = new Map(nodes.map((n) => [n.id, n]));
  const groupIds = new Set<string>();
  for (const id of selectedIds) {
    const g = byId.get(id)?.groupId;
    if (g) groupIds.add(g);
  }
  if (!groupIds.size) return [...selectedIds];
  const out = new Set(selectedIds);
  for (const n of nodes) {
    if (n.groupId && groupIds.has(n.groupId)) out.add(n.id);
  }
  return [...out];
}

export function groupNodes(nodes: PlanNode[], ids: string[]): PlanNode[] {
  if (ids.length < 2) return nodes;
  const set = new Set(ids);
  const gid = newNodeId("g");
  return nodes.map((n) => (set.has(n.id) ? { ...n, groupId: gid } : n));
}

export function ungroupNodes(nodes: PlanNode[], ids: string[]): PlanNode[] {
  const set = new Set(ids);
  const groups = new Set(
    nodes.filter((n) => set.has(n.id) && n.groupId).map((n) => n.groupId!),
  );
  return nodes.map((n) =>
    n.groupId && (set.has(n.id) || groups.has(n.groupId))
      ? { ...n, groupId: null }
      : n,
  );
}

function remapNode(node: PlanNode, idMap: Map<string, string>, groupMap: Map<string, string>): PlanNode {
  const next: PlanNode = {
    ...structuredClone(node),
    id: idMap.get(node.id) ?? newNodeId(),
  };
  if (next.bookableId) next.bookableId = newNodeId("bk");
  if (next.groupId) {
    if (!groupMap.has(next.groupId)) groupMap.set(next.groupId, newNodeId("g"));
    next.groupId = groupMap.get(next.groupId)!;
  }
  return next;
}

export function duplicateNodes(
  plan: PlanDocument,
  ids: string[],
  offset = 24,
): { plan: PlanDocument; newIds: string[] } {
  const set = new Set(expandSelectionWithGroups(plan.nodes, ids));
  const sources = plan.nodes.filter((n) => set.has(n.id));
  const idMap = new Map<string, string>();
  const groupMap = new Map<string, string>();
  for (const n of sources) idMap.set(n.id, newNodeId());

  const created = sources.map((n) => {
    const copy = remapNode(n, idMap, groupMap);
    if (copy.frame) {
      copy.frame = {
        ...copy.frame,
        x: copy.frame.x + offset,
        y: copy.frame.y + offset,
      };
    }
    if (copy.points) {
      copy.points = copy.points.map((p) => ({ x: p.x + offset, y: p.y + offset }));
    }
    if (copy.holes) {
      copy.holes = copy.holes.map((ring) =>
        ring.map((p) => ({ x: p.x + offset, y: p.y + offset })),
      );
    }
    return copy;
  });

  return {
    plan: { ...plan, nodes: [...plan.nodes, ...created] },
    newIds: created.map((n) => n.id),
  };
}

export function translateNode(node: PlanNode, dx: number, dy: number): PlanNode {
  if (node.points?.length) {
    const points = node.points.map((pt) => ({ x: pt.x + dx, y: pt.y + dy }));
    const holes = node.holes?.map((ring) =>
      ring.map((pt) => ({ x: pt.x + dx, y: pt.y + dy })),
    );
    const xs = points.map((pt) => pt.x);
    const ys = points.map((pt) => pt.y);
    return {
      ...node,
      points,
      holes,
      frame: {
        x: Math.min(...xs),
        y: Math.min(...ys),
        w: Math.max(1, Math.max(...xs) - Math.min(...xs)),
        h: Math.max(1, Math.max(...ys) - Math.min(...ys)),
      },
    };
  }
  if (node.frame) {
    return {
      ...node,
      frame: { ...node.frame, x: node.frame.x + dx, y: node.frame.y + dy },
    };
  }
  return node;
}

/** Как красиво разложить несколько emoji в одну связку. */
export type EmojiClusterLayout = "row" | "arc" | "grid" | "pair";

/** Смещения центров относительно якоря связки (0,0). */
export function emojiClusterOffsets(
  count: number,
  layout: EmojiClusterLayout,
  size: number,
  gap = 10,
): PlanPoint[] {
  const n = Math.max(1, Math.min(count, 8));
  const step = size + gap;

  if (layout === "pair" || (layout === "row" && n === 2)) {
    const half = step / 2;
    return [
      { x: -half, y: 0 },
      { x: half, y: 0 },
    ].slice(0, n);
  }

  if (layout === "row") {
    const total = (n - 1) * step;
    return Array.from({ length: n }, (_, i) => ({
      x: -total / 2 + i * step,
      y: 0,
    }));
  }

  if (layout === "arc") {
    const radius = Math.max(size * 0.85, (n - 1) * step * 0.42);
    const span = Math.min(Math.PI * 0.85, (n - 1) * 0.55);
    const start = Math.PI / 2 + span / 2;
    return Array.from({ length: n }, (_, i) => {
      const t = n === 1 ? Math.PI / 2 : start - (span * i) / Math.max(1, n - 1);
      return { x: Math.cos(t) * radius, y: -Math.sin(t) * radius * 0.55 };
    });
  }

  // grid — 2 колонки, потом 3
  const cols = n <= 4 ? 2 : 3;
  const rows = Math.ceil(n / cols);
  const out: PlanPoint[] = [];
  for (let i = 0; i < n; i++) {
    const col = i % cols;
    const row = Math.floor(i / cols);
    const rowCount = Math.min(cols, n - row * cols);
    const rowWidth = (rowCount - 1) * step;
    out.push({
      x: -rowWidth / 2 + col * step,
      y: -((rows - 1) * step) / 2 + row * step,
    });
  }
  return out;
}

/** Новая связка emoji (уже с одним groupId). */
export function createEmojiCluster(opts: {
  center: PlanPoint;
  glyphs: string[];
  layout: EmojiClusterLayout;
  size: number;
  zBase?: number;
  /** Место с ценником или только декор. */
  role?: "decor" | "bookable";
}): PlanNode[] {
  const glyphs = opts.glyphs.filter((g) => g.trim().length > 0);
  if (!glyphs.length) return [];
  const size = opts.size;
  const gid = newNodeId("g");
  const role = opts.role ?? "decor";
  const offsets = emojiClusterOffsets(glyphs.length, opts.layout, size);
  return glyphs.map((label, i) => {
    const o = offsets[i] ?? { x: 0, y: 0 };
    const id = newNodeId("e");
    return {
      id,
      kind: "emoji" as const,
      role,
      label,
      frame: {
        x: opts.center.x + o.x - size / 2,
        y: opts.center.y + o.y - size / 2,
        w: size,
        h: size,
      },
      style: {
        fill: null,
        stroke: "transparent",
        strokeWidth: 0,
        radius: 0,
        opacity: 1,
      },
      zIndex: (opts.zBase ?? 20) + i,
      bookableId: role === "bookable" ? newNodeId("bk") : null,
      groupId: gid,
    } satisfies PlanNode;
  });
}

/** Разложить выделенные emoji по схеме и связать в одну группу. */
export function arrangeAndGroupEmojis(
  nodes: PlanNode[],
  ids: string[],
  layout: EmojiClusterLayout,
): PlanNode[] {
  const set = new Set(ids);
  const emojis = nodes.filter((n) => set.has(n.id) && n.kind === "emoji" && n.frame);
  if (emojis.length < 2) return nodes;

  let cx = 0;
  let cy = 0;
  for (const n of emojis) {
    const c = nodeCenter(n);
    cx += c.x;
    cy += c.y;
  }
  cx /= emojis.length;
  cy /= emojis.length;

  const avgSize =
    emojis.reduce((s, n) => s + (n.frame?.w ?? 56), 0) / emojis.length;
  const offsets = emojiClusterOffsets(emojis.length, layout, avgSize);
  const gid = newNodeId("g");
  const byId = new Map(emojis.map((n, i) => [n.id, i] as const));

  return nodes.map((n) => {
    const idx = byId.get(n.id);
    if (idx == null || !n.frame) return n;
    const o = offsets[idx] ?? { x: 0, y: 0 };
    const size = n.frame.w;
    return {
      ...n,
      groupId: gid,
      frame: {
        x: cx + o.x - size / 2,
        y: cy + o.y - size / 2,
        w: size,
        h: size,
      },
    };
  });
}

/** BBox группы (для обводки связки на канве). */
export function groupBounds(
  nodes: PlanNode[],
  groupId: string,
  pad = 10,
): { x: number; y: number; w: number; h: number } | null {
  const members = nodes.filter((n) => n.groupId === groupId && n.frame);
  if (!members.length) return null;
  let minX = Infinity;
  let minY = Infinity;
  let maxX = -Infinity;
  let maxY = -Infinity;
  for (const n of members) {
    const f = n.frame!;
    minX = Math.min(minX, f.x);
    minY = Math.min(minY, f.y);
    maxX = Math.max(maxX, f.x + f.w);
    maxY = Math.max(maxY, f.y + f.h);
  }
  return {
    x: minX - pad,
    y: minY - pad,
    w: maxX - minX + pad * 2,
    h: maxY - minY + pad * 2,
  };
}

