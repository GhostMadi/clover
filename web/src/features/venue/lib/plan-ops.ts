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
