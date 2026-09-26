"use client";

import {
  ArrowLeft,
  Circle,
  Combine,
  Copy,
  Download,
  Eraser,
  FolderOpen,
  Group,
  Hand,
  Hexagon,
  LayoutGrid,
  Link2,
  Magnet,
  MoreHorizontal,
  Minus,
  MousePointer2,
  PanelRightClose,
  PanelRightOpen,
  Pencil,
  Plus,
  Redo2,
  Save,
  Smile,
  Square,
  SplitSquareVertical,
  Trash2,
  Type,
  Undo2,
  Ungroup,
  Braces,
} from "lucide-react";
import Link from "next/link";
import {
  useCallback,
  useEffect,
  useMemo,
  useRef,
  useState,
  type PointerEvent as ReactPointerEvent,
  type ReactNode,
} from "react";
import { AppButton } from "@/components/shared/app-button";
import {
  createBanquetStarterPlan,
  createCafeBuilding,
  createCinemaStarterPlan,
} from "@/features/venue/lib/plan-editor-export";
import {
  boundsIntersect,
  canBooleanMerge,
  nodeBounds,
  ringsToPathD,
  subtractNodes,
  unionNodes,
} from "@/features/venue/lib/plan-boolean";
import {
  DEFAULT_EMOJI_SIZE,
  PLAN_GRID,
  VENUE_EMOJI_PRESETS,
  VENUE_FILL_PRESETS,
  VENUE_STROKE_PRESETS,
  createEmptyPlan,
  defaultStyle,
  newNodeId,
  type EditorTool,
  type PlanDocument,
  type PlanNode,
  type PlanPoint,
} from "@/features/venue/lib/plan-editor-types";
import {
  buildingFromPlan,
  createNextFloor,
  sortFloors,
  upsertFloor,
  type VenueBuildingDraft,
} from "@/features/venue/lib/plan-floors";
import {
  arrangeAndGroupEmojis,
  createEmojiCluster,
  duplicateNodes,
  expandSelectionWithGroups,
  groupBounds,
  groupNodes,
  nodeCenter,
  snapPoint,
  translateNode,
  ungroupNodes,
  type EmojiClusterLayout,
} from "@/features/venue/lib/plan-ops";
import { PLAN_CRAZY_EMOJI_BUILDING, planCrazyEmojiJson } from "@/features/venue/lib/plan-crazy-emoji-example";
import {
  PLAN_JSON_AI_HINT,
  planFullExampleJson,
} from "@/features/venue/lib/plan-full-example";
import { parsePlanJsonText } from "@/features/venue/lib/plan-json-import";
import {
  downloadPlanJson,
  loadBuildingDraft,
  readPlanJsonFile,
  saveBuildingDraft,
} from "@/features/venue/lib/plan-storage";

type Corner = "nw" | "ne" | "sw" | "se";

type DragState =
  | { mode: "draw-shape"; start: PlanPoint; shift: boolean }
  | { mode: "move"; start: PlanPoint; origins: PlanNode[] }
  | {
      mode: "resize";
      corner: Corner;
      origin: PlanNode;
      /** Для emoji / Shift — квадрат. */
      lockSquare: boolean;
    }
  | { mode: "marquee"; start: PlanPoint; additive: boolean }
  | { mode: "pan"; startX: number; startY: number; panX: number; panY: number }
  | null;

const DEFAULT_RECT = { w: 140, h: 100 };
const DEFAULT_ELLIPSE = { w: 110, h: 110 };
const CLICK_THRESHOLD = 5;
/** Радиус «магнита» к первой точке — можно замкнуть фигуру. */
const CLOSE_SNAP_PX = 18;
const HANDLE_HIT_PX = 12;
const MIN_SIZE = 16;

function clonePlan(plan: PlanDocument): PlanDocument {
  return structuredClone(plan);
}

function ensurePlan(value: PlanDocument | null | undefined): PlanDocument {
  if (value && Array.isArray(value.nodes)) return value;
  return createEmptyPlan();
}

function dist(a: PlanPoint, b: PlanPoint) {
  return Math.hypot(b.x - a.x, b.y - a.y);
}

function hitTest(node: PlanNode, p: PlanPoint): boolean {
  if ((node.kind === "line" || node.kind === "path") && node.points && node.points.length >= 2) {
    for (let i = 0; i < node.points.length - 1; i++) {
      const a = node.points[i]!;
      const b = node.points[i + 1]!;
      const len = Math.hypot(b.x - a.x, b.y - a.y) || 1;
      const d =
        Math.abs((b.y - a.y) * p.x - (b.x - a.x) * p.y + b.x * a.y - b.y * a.x) / len;
      const t = ((p.x - a.x) * (b.x - a.x) + (p.y - a.y) * (b.y - a.y)) / (len * len);
      if (d < 8 && t >= -0.05 && t <= 1.05) return true;
    }
    return false;
  }
  if (node.kind === "polygon" && node.points?.length) {
    const xs = node.points.map((pt) => pt.x);
    const ys = node.points.map((pt) => pt.y);
    return (
      p.x >= Math.min(...xs) &&
      p.x <= Math.max(...xs) &&
      p.y >= Math.min(...ys) &&
      p.y <= Math.max(...ys)
    );
  }
  if (!node.frame) return false;
  const { x, y, w, h } = node.frame;
  if (node.kind === "ellipse") {
    const cx = x + w / 2;
    const cy = y + h / 2;
    const rx = Math.max(1, w / 2);
    const ry = Math.max(1, h / 2);
    return ((p.x - cx) / rx) ** 2 + ((p.y - cy) / ry) ** 2 <= 1;
  }
  return p.x >= x && p.x <= x + w && p.y >= y && p.y <= y + h;
}

function normalizeFrame(a: PlanPoint, b: PlanPoint, shift: boolean) {
  let w = Math.abs(b.x - a.x);
  let h = Math.abs(b.y - a.y);
  if (shift) {
    const s = Math.max(w, h);
    w = s;
    h = s;
  }
  w = Math.max(8, w);
  h = Math.max(8, h);
  const x = b.x < a.x ? a.x - w : a.x;
  const y = b.y < a.y ? a.y - h : a.y;
  return { x, y, w, h };
}

function hitTestCorner(
  frame: { x: number; y: number; w: number; h: number },
  p: PlanPoint,
  hitPx = HANDLE_HIT_PX,
): Corner | null {
  const corners: [Corner, number, number][] = [
    ["nw", frame.x, frame.y],
    ["ne", frame.x + frame.w, frame.y],
    ["sw", frame.x, frame.y + frame.h],
    ["se", frame.x + frame.w, frame.y + frame.h],
  ];
  for (const [c, cx, cy] of corners) {
    if (Math.hypot(p.x - cx, p.y - cy) <= hitPx) return c;
  }
  return null;
}

function resizeFrame(
  origin: { x: number; y: number; w: number; h: number },
  corner: Corner,
  p: PlanPoint,
  lockSquare: boolean,
): { x: number; y: number; w: number; h: number } {
  let x1 = origin.x;
  let y1 = origin.y;
  let x2 = origin.x + origin.w;
  let y2 = origin.y + origin.h;

  if (corner === "nw") {
    x1 = p.x;
    y1 = p.y;
  } else if (corner === "ne") {
    x2 = p.x;
    y1 = p.y;
  } else if (corner === "sw") {
    x1 = p.x;
    y2 = p.y;
  } else {
    x2 = p.x;
    y2 = p.y;
  }

  let x = Math.min(x1, x2);
  let y = Math.min(y1, y2);
  let w = Math.max(MIN_SIZE, Math.abs(x2 - x1));
  let h = Math.max(MIN_SIZE, Math.abs(y2 - y1));

  if (lockSquare) {
    const s = Math.max(w, h);
    if (corner === "se") {
      w = s;
      h = s;
    } else if (corner === "sw") {
      x = x2 - s;
      w = s;
      h = s;
    } else if (corner === "ne") {
      y = y2 - s;
      w = s;
      h = s;
    } else {
      x = x2 - s;
      y = y2 - s;
      w = s;
      h = s;
    }
  }

  return { x, y, w, h };
}

function cornerCursor(corner: Corner): string {
  return corner === "nw" || corner === "se" ? "nwse-resize" : "nesw-resize";
}

function cursorFor(tool: EditorTool, drawing: boolean) {
  if (tool === "pan") return "grab";
  if (tool === "select") return "default";
  if (drawing) return "crosshair";
  return "crosshair";
}

export function VenuePlanEditorView({
  venueId,
  venueName,
  backHref,
}: {
  venueId: string;
  venueName?: string;
  /** Куда «Назад». По умолчанию — хаб заведения Брони. */
  backHref?: string;
}) {
  const [plan, setPlan] = useState<PlanDocument>(() => createEmptyPlan());
  const [floors, setFloors] = useState<PlanDocument[]>([]);
  const [tool, setTool] = useState<EditorTool>("select");
  const [selectedIds, setSelectedIds] = useState<string[]>([]);
  /** Кликнутый узел внутри группы (для resize / фокуса). */
  const [focusId, setFocusId] = useState<string | null>(null);
  const [fill, setFill] = useState("#FFA39E");
  const [stroke, setStroke] = useState("#B54B45");
  const [strokeWidth, setStrokeWidth] = useState(2);
  const [radius, setRadius] = useState(16);
  /** Новые emoji: место (для ценника в сервисах) vs декор. */
  const [placeEmojiDefault, setPlaceEmojiDefault] = useState(true);
  const [activeEmoji, setActiveEmoji] = useState<string>("😀");
  const [activeText, setActiveText] = useState("Текст");
  const [emojiSize, setEmojiSize] = useState(DEFAULT_EMOJI_SIZE);
  const [clusterLayout, setClusterLayout] = useState<EmojiClusterLayout>("row");
  const [clusterCount, setClusterCount] = useState(3);
  const [pathPoints, setPathPoints] = useState<PlanPoint[]>([]);
  const [hoverPoint, setHoverPoint] = useState<PlanPoint | null>(null);
  const [closeSnap, setCloseSnap] = useState(false);
  const [shapePreview, setShapePreview] = useState<{
    a: PlanPoint;
    b: PlanPoint;
    shift: boolean;
  } | null>(null);
  const [marquee, setMarquee] = useState<{ a: PlanPoint; b: PlanPoint } | null>(null);
  const [pan, setPan] = useState({ x: 40, y: 40 });
  const [zoom, setZoom] = useState(1);
  const [history, setHistory] = useState<PlanDocument[]>([]);
  const [future, setFuture] = useState<PlanDocument[]>([]);
  const [spaceDown, setSpaceDown] = useState(false);
  const [hoverCorner, setHoverCorner] = useState<Corner | null>(null);
  const [rightOpen, setRightOpen] = useState(true);
  const [snapOn, setSnapOn] = useState(true);
  const [draftReady, setDraftReady] = useState(false);
  const [jsonPasteOpen, setJsonPasteOpen] = useState(false);
  const [jsonPasteText, setJsonPasteText] = useState("");
  const [jsonPasteError, setJsonPasteError] = useState<string | null>(null);
  const [fileMenuOpen, setFileMenuOpen] = useState(false);
  const [editMoreOpen, setEditMoreOpen] = useState(false);

  const dragRef = useRef<DragState>(null);
  const moveSnapshotRef = useRef<PlanDocument | null>(null);
  const svgRef = useRef<SVGSVGElement | null>(null);
  const clipboardRef = useRef<PlanNode[]>([]);
  const fileInputRef = useRef<HTMLInputElement | null>(null);
  const planRef = useRef(plan);
  const floorsRef = useRef(floors);
  const panRef = useRef(pan);
  const zoomRef = useRef(zoom);
  const snapOnRef = useRef(snapOn);
  planRef.current = ensurePlan(plan);
  floorsRef.current = floors;
  panRef.current = pan;
  zoomRef.current = zoom;
  snapOnRef.current = snapOn;

  const commitPlanIntoFloors = useCallback((current: PlanDocument): PlanDocument[] => {
    return upsertFloor(
      {
        version: 1,
        floors: floorsRef.current,
        activeFloorKey: current.floorKey,
      },
      current,
    ).floors;
  }, []);

  const buildingSnapshot = useCallback(
    (current: PlanDocument, floorList?: PlanDocument[]): VenueBuildingDraft => {
      const upserted = floorList ?? commitPlanIntoFloors(current);
      return {
        version: 1,
        floors: upserted,
        activeFloorKey: current.floorKey,
      };
    },
    [commitPlanIntoFloors],
  );

  const resetFloorSession = useCallback(() => {
    setSelectedIds([]);
    setHistory([]);
    setFuture([]);
    setPathPoints([]);
    setHoverPoint(null);
    setCloseSnap(false);
  }, []);

  const applyBuilding = useCallback(
    (building: VenueBuildingDraft) => {
      const sorted = sortFloors(building.floors.map(ensurePlan));
      const active = ensurePlan(
        sorted.find((f) => f.floorKey === building.activeFloorKey) ?? sorted[0]!,
      );
      floorsRef.current = sorted;
      setFloors(sorted);
      setPlan(active);
      resetFloorSession();
    },
    [resetFloorSession],
  );

  // При выборе объекта сразу открыть правую панель — блок «Привязка» сверху.
  useEffect(() => {
    if (selectedIds.length === 1) setRightOpen(true);
  }, [selectedIds]);

  // Черновик здания из localStorage при открытии.
  useEffect(() => {
    const draft = loadBuildingDraft(venueId);
    const building = draft ?? createCafeBuilding();
    applyBuilding(building);
    setDraftReady(true);
  }, [venueId, applyBuilding]);

  // Автосохранение черновика здания.
  useEffect(() => {
    if (!draftReady) return;
    const t = window.setTimeout(() => {
      const current = ensurePlan(planRef.current);
      const upserted = commitPlanIntoFloors(current);
      floorsRef.current = upserted;
      setFloors(upserted);
      saveBuildingDraft(venueId, {
        version: 1,
        floors: upserted,
        activeFloorKey: current.floorKey,
      });
    }, 800);
    return () => window.clearTimeout(t);
  }, [plan, venueId, draftReady, commitPlanIntoFloors]);

  // Защита: в историю раньше мог попасть null из-за async setState.
  useEffect(() => {
    if (!plan || !Array.isArray(plan.nodes)) {
      setPlan(createEmptyPlan());
    }
  }, [plan]);

  const selectedNodes = useMemo(
    () => (plan?.nodes ?? []).filter((n) => selectedIds.includes(n.id)),
    [plan?.nodes, selectedIds],
  );
  const selected = selectedNodes.length === 1 ? selectedNodes[0]! : null;
  const primarySelected = selectedNodes[0] ?? null;
  const booleanReady =
    selectedNodes.length >= 2 && selectedNodes.every(canBooleanMerge);
  const selectedEmojis = useMemo(
    () => selectedNodes.filter((n) => n.kind === "emoji"),
    [selectedNodes],
  );
  const canLinkEmojis = selectedEmojis.length >= 2;

  const emojiGroupHulls = useMemo(() => {
    const selected = new Set(selectedIds);
    const gids = new Set<string>();
    for (const n of plan.nodes) {
      if (n.kind === "emoji" && n.groupId && selected.has(n.id)) gids.add(n.groupId);
    }
    const hulls: Array<{
      gid: string;
      bounds: NonNullable<ReturnType<typeof groupBounds>>;
      centers: PlanPoint[];
    }> = [];
    for (const gid of gids) {
      const members = plan.nodes.filter((n) => n.groupId === gid && n.kind === "emoji");
      if (members.length < 2) continue;
      // Показываем обводку только если связка сейчас выделена.
      if (!members.every((m) => selected.has(m.id))) continue;
      const bounds = groupBounds(plan.nodes, gid, 12);
      if (!bounds) continue;
      hulls.push({
        gid,
        bounds,
        centers: members.map(nodeCenter),
      });
    }
    return hulls;
  }, [plan.nodes, selectedIds]);

  const isPathTool = tool === "line" || tool === "polygon";
  const drawingPath = pathPoints.length > 0;

  const pushHistory = useCallback((next: PlanDocument) => {
    const snapshot = clonePlan(ensurePlan(planRef.current));
    const safeNext = ensurePlan(next);
    setHistory((h) => [...h.slice(-50), snapshot]);
    setFuture([]);
    setPlan(safeNext);
  }, []);

  const undo = useCallback(() => {
    setHistory((h) => {
      if (!h.length) return h;
      const prev = ensurePlan(h[h.length - 1]);
      const current = clonePlan(ensurePlan(planRef.current));
      setFuture((f) => [current, ...f]);
      setPlan(prev);
      return h.slice(0, -1);
    });
  }, []);

  const redo = useCallback(() => {
    setFuture((f) => {
      if (!f.length) return f;
      const next = ensurePlan(f[0]);
      const current = clonePlan(ensurePlan(planRef.current));
      setHistory((h) => [...h, current]);
      setPlan(next);
      return f.slice(1);
    });
  }, []);

  const clientToCanvas = (e: {
    clientX: number;
    clientY: number;
    altKey?: boolean;
  }): PlanPoint => {
    const svg = svgRef.current;
    if (!svg) return { x: 0, y: 0 };
    const rect = svg.getBoundingClientRect();
    const raw = {
      x: (e.clientX - rect.left - pan.x) / zoom,
      y: (e.clientY - rect.top - pan.y) / zoom,
    };
    return snapPoint(raw, snapOnRef.current && !e.altKey);
  };

  const screenHitPx = (px: number) => px / zoom;

  const runDuplicate = useCallback(() => {
    if (!selectedIds.length) return;
    const { plan: next, newIds } = duplicateNodes(planRef.current, selectedIds, 24);
    pushHistory(next);
    setSelectedIds(newIds);
  }, [selectedIds, pushHistory]);

  const runCopy = useCallback(() => {
    if (!selectedIds.length) return;
    const ids = expandSelectionWithGroups(planRef.current.nodes, selectedIds);
    clipboardRef.current = planRef.current.nodes
      .filter((n) => ids.includes(n.id))
      .map((n) => structuredClone(n));
  }, [selectedIds]);

  const runPaste = useCallback(() => {
    const clip = clipboardRef.current;
    if (!clip.length) return;
    const sandbox: PlanDocument = { ...planRef.current, nodes: clip };
    const { plan: sandboxed, newIds } = duplicateNodes(
      sandbox,
      clip.map((n) => n.id),
      24,
    );
    const created = sandboxed.nodes.filter((n) => newIds.includes(n.id));
    pushHistory({
      ...planRef.current,
      nodes: [...planRef.current.nodes, ...created],
    });
    setSelectedIds(newIds);
  }, [pushHistory]);

  const runGroup = useCallback(() => {
    if (selectedIds.length < 2) return;
    pushHistory({
      ...planRef.current,
      nodes: groupNodes(planRef.current.nodes, selectedIds),
    });
  }, [selectedIds, pushHistory]);

  const runUngroup = useCallback(() => {
    if (!selectedIds.length) return;
    pushHistory({
      ...planRef.current,
      nodes: ungroupNodes(planRef.current.nodes, selectedIds),
    });
  }, [selectedIds, pushHistory]);

  /** Связать выделенные emoji в одну группу — позиции как расставил хозяин. */
  const runLinkEmojis = useCallback(() => {
    const ids = selectedNodes.filter((n) => n.kind === "emoji").map((n) => n.id);
    if (ids.length < 2) return;
    pushHistory({
      ...planRef.current,
      nodes: groupNodes(planRef.current.nodes, ids),
    });
    setSelectedIds(ids);
  }, [selectedNodes, pushHistory]);

  /** Красиво переложить выделенные emoji (ряд/дуга/сетка) и связать. */
  const runArrangeEmojis = useCallback(
    (layout: EmojiClusterLayout = clusterLayout) => {
      const ids = selectedNodes.filter((n) => n.kind === "emoji").map((n) => n.id);
      if (ids.length < 2) return;
      pushHistory({
        ...planRef.current,
        nodes: arrangeAndGroupEmojis(planRef.current.nodes, ids, layout),
      });
      setSelectedIds(ids);
    },
    [selectedNodes, clusterLayout, pushHistory],
  );

  /** Вставить новую связку emoji в центр холста. */
  const insertEmojiCluster = useCallback(
    (layout: EmojiClusterLayout = clusterLayout, count = clusterCount) => {
      const glyphs = Array.from({ length: Math.max(2, Math.min(count, 6)) }, () => activeEmoji);
      const created = createEmojiCluster({
        center: {
          x: planRef.current.canvas.width / 2,
          y: planRef.current.canvas.height / 2,
        },
        glyphs,
        layout,
        size: emojiSize,
        role: placeEmojiDefault ? "bookable" : "decor",
      });
      if (!created.length) return;
      pushHistory({
        ...planRef.current,
        nodes: [...planRef.current.nodes, ...created],
      });
      setSelectedIds(created.map((n) => n.id));
      setTool("select");
    },
    [activeEmoji, clusterLayout, clusterCount, emojiSize, placeEmojiDefault, pushHistory],
  );

  const saveDraftNow = useCallback(() => {
    const current = ensurePlan(planRef.current);
    const building = buildingSnapshot(current);
    floorsRef.current = building.floors;
    setFloors(building.floors);
    saveBuildingDraft(venueId, building);
  }, [venueId, buildingSnapshot]);

  const switchFloor = useCallback(
    (floorKey: string) => {
      const current = ensurePlan(planRef.current);
      if (current.floorKey === floorKey) return;
      const upserted = commitPlanIntoFloors(current);
      const target = upserted.find((f) => f.floorKey === floorKey);
      if (!target) return;
      floorsRef.current = upserted;
      setFloors(upserted);
      setPlan(ensurePlan(target));
      resetFloorSession();
    },
    [commitPlanIntoFloors, resetFloorSession],
  );

  const addFloor = useCallback(() => {
    const current = ensurePlan(planRef.current);
    const upserted = commitPlanIntoFloors(current);
    const created = createNextFloor(upserted);
    const nextFloors = [...upserted, created];
    floorsRef.current = nextFloors;
    setFloors(nextFloors);
    setPlan(created);
    resetFloorSession();
  }, [commitPlanIntoFloors, resetFloorSession]);

  const renameFloor = useCallback(
    (floorKey: string) => {
      const current = ensurePlan(planRef.current);
      const source =
        current.floorKey === floorKey
          ? current
          : floorsRef.current.find((f) => f.floorKey === floorKey);
      if (!source) return;
      const next = window.prompt("Название этажа", source.label ?? "");
      if (next == null) return;
      const label = next.trim() || source.label || "Этаж";
      if (current.floorKey === floorKey) {
        setPlan((p) => ({ ...ensurePlan(p), label }));
      }
      setFloors((fs) => {
        const nextFloors = fs.map((f) =>
          f.floorKey === floorKey ? { ...f, label } : f,
        );
        floorsRef.current = nextFloors;
        return nextFloors;
      });
    },
    [],
  );

  const deleteFloor = useCallback(
    (floorKey: string) => {
      if (floorsRef.current.length <= 1) return;
      if (!window.confirm("Удалить этот этаж? План этажа будет потерян.")) return;
      const current = ensurePlan(planRef.current);
      const upserted =
        current.floorKey === floorKey
          ? floorsRef.current
          : commitPlanIntoFloors(current);
      const nextFloors = upserted.filter((f) => f.floorKey !== floorKey);
      if (!nextFloors.length) return;
      const nextActive =
        current.floorKey === floorKey
          ? nextFloors[0]!
          : nextFloors.find((f) => f.floorKey === current.floorKey) ?? nextFloors[0]!;
      floorsRef.current = nextFloors;
      setFloors(nextFloors);
      setPlan(ensurePlan(nextActive));
      resetFloorSession();
    },
    [commitPlanIntoFloors, resetFloorSession],
  );

  const downloadBuilding = useCallback(() => {
    const current = ensurePlan(planRef.current);
    const building = buildingSnapshot(current);
    floorsRef.current = building.floors;
    setFloors(building.floors);
    downloadPlanJson(building, `venue-plan-${venueId}.json`);
  }, [venueId, buildingSnapshot]);

  const makeShapeNode = (
    kind: "rect" | "ellipse",
    frame: { x: number; y: number; w: number; h: number },
  ): PlanNode => {
    const id = newNodeId();
    return {
      id,
      kind,
      role: "decor",
      label: null,
      frame,
      style: defaultStyle({
        fill,
        stroke,
        strokeWidth,
        radius: kind === "ellipse" ? 999 : radius,
      }),
      zIndex: 2,
      bookableId: null,
    };
  };

  const commitPath = useCallback(
    (closed: boolean) => {
      if (pathPoints.length < 2) {
        setPathPoints([]);
        setHoverPoint(null);
        return;
      }
      const id = newNodeId();
      const node: PlanNode = {
        id,
        kind: closed ? "polygon" : "path",
        role: "decor",
        label: null,
        points: [...pathPoints],
        style: defaultStyle({
          fill: closed ? fill : null,
          stroke,
          strokeWidth: Math.max(2, strokeWidth),
          radius: 0,
          opacity: closed ? 0.92 : 1,
        }),
        zIndex: 3,
        bookableId: null,
      };
      pushHistory({ ...planRef.current, nodes: [...planRef.current.nodes, node] });
      setSelectedIds([id]);
      setPathPoints([]);
      setHoverPoint(null);
    },
    [pathPoints, fill, stroke, strokeWidth, pushHistory],
  );

  const cancelPath = () => {
    setPathPoints([]);
    setHoverPoint(null);
    setCloseSnap(false);
  };

  const openPlanFile = async (file: File | undefined) => {
    if (!file) return;
    const building = await readPlanJsonFile(file);
    if (!building) {
      window.alert("Не удалось прочитать JSON плана. Проверьте формат.");
      return;
    }
    applyBuilding(building);
  };

  const applyPastedJson = () => {
    const building = parsePlanJsonText(jsonPasteText);
    if (!building) {
      setJsonPasteError("Невалидный JSON или неизвестный формат плана.");
      return;
    }
    applyBuilding(building);
    setJsonPasteOpen(false);
    setJsonPasteText("");
    setJsonPasteError(null);
  };

  /** Подсказка замкнуть: ≥3 точек и курсор у первой вершины. */
  const resolvePathHover = useCallback((raw: PlanPoint, points: PlanPoint[]) => {
    const first = points[0];
    const snapR = CLOSE_SNAP_PX / zoomRef.current;
    if (first && points.length >= 3 && dist(raw, first) <= snapR) {
      return { point: first, snap: true };
    }
    return { point: raw, snap: false };
  }, []);

  const deleteSelected = useCallback(() => {
    if (!selectedIds.length) return;
    const drop = new Set(selectedIds);
    pushHistory({
      ...planRef.current,
      nodes: planRef.current.nodes.filter((n) => !drop.has(n.id)),
    });
    setSelectedIds([]);
  }, [selectedIds, pushHistory]);

  const updateSelected = (patch: Partial<PlanNode>) => {
    if (!selectedNodes.length) return;
    const ids = new Set(selectedIds);
    pushHistory({
      ...plan,
      nodes: plan.nodes.map((n) => (ids.has(n.id) ? { ...n, ...patch } : n)),
    });
  };


  const updateSelectedStyle = (patch: Partial<PlanNode["style"]>) => {
    if (!selectedNodes.length) return;
    const ids = new Set(selectedIds);
    pushHistory({
      ...plan,
      nodes: plan.nodes.map((n) =>
        ids.has(n.id) ? { ...n, style: { ...n.style, ...patch } } : n,
      ),
    });
  };

  /** Один UI цвета: с выделением — правка объекта(ов), без — кисть для новых фигур. */
  const applyFill = (c: string) => {
    setFill(c);
    if (selectedNodes.some((n) => n.kind !== "emoji")) {
      const ids = new Set(selectedNodes.filter((n) => n.kind !== "emoji").map((n) => n.id));
      pushHistory({
        ...plan,
        nodes: plan.nodes.map((n) =>
          ids.has(n.id) ? { ...n, style: { ...n.style, fill: c } } : n,
        ),
      });
    }
  };

  const applyStroke = (c: string) => {
    setStroke(c);
    if (selectedNodes.some((n) => n.kind !== "emoji")) {
      const ids = new Set(selectedNodes.filter((n) => n.kind !== "emoji").map((n) => n.id));
      pushHistory({
        ...plan,
        nodes: plan.nodes.map((n) =>
          ids.has(n.id) ? { ...n, style: { ...n.style, stroke: c } } : n,
        ),
      });
    }
  };

  const applyStrokeWidth = (w: number) => {
    setStrokeWidth(w);
    if (selectedNodes.some((n) => n.kind !== "emoji")) {
      const ids = new Set(selectedNodes.filter((n) => n.kind !== "emoji").map((n) => n.id));
      pushHistory({
        ...plan,
        nodes: plan.nodes.map((n) =>
          ids.has(n.id) ? { ...n, style: { ...n.style, strokeWidth: w } } : n,
        ),
      });
    }
  };

  const applyRadius = (r: number) => {
    setRadius(r);
    const ids = new Set(selectedNodes.filter((n) => n.kind === "rect").map((n) => n.id));
    if (ids.size) {
      pushHistory({
        ...plan,
        nodes: plan.nodes.map((n) =>
          ids.has(n.id) ? { ...n, style: { ...n.style, radius: r } } : n,
        ),
      });
    }
  };

  const applyCanvasBackground = (c: string) => {
    pushHistory({
      ...plan,
      canvas: { ...plan.canvas, background: c },
    });
  };

  const runUnion = () => {
    if (!booleanReady) return;
    const created = unionNodes(selectedNodes);
    if (!created?.length) return;
    const drop = new Set(selectedIds);
    pushHistory({
      ...plan,
      nodes: [...plan.nodes.filter((n) => !drop.has(n.id)), ...created],
    });
    setSelectedIds(created.map((n) => n.id));
  };

  const runSubtract = () => {
    if (!booleanReady) return;
    const created = subtractNodes(selectedNodes);
    if (!created?.length) return;
    const drop = new Set(selectedIds);
    pushHistory({
      ...plan,
      nodes: [...plan.nodes.filter((n) => !drop.has(n.id)), ...created],
    });
    setSelectedIds(created.map((n) => n.id));
  };

  // При выборе фигуры подставляем её стили в те же контролы.
  useEffect(() => {
    const node = primarySelected;
    if (!node || node.kind === "emoji") return;
    if (node.style.fill) setFill(node.style.fill);
    setStroke(node.style.stroke);
    setStrokeWidth(node.style.strokeWidth);
    if (node.kind === "rect") setRadius(node.style.radius);
  }, [primarySelected?.id]);

  useEffect(() => {
    const onKeyDown = (e: KeyboardEvent) => {
      const typing =
        e.target instanceof HTMLInputElement ||
        e.target instanceof HTMLTextAreaElement ||
        (e.target instanceof HTMLElement && e.target.isContentEditable);

      if (e.code === "Space" && !typing) {
        e.preventDefault();
        setSpaceDown(true);
      }
      if (e.key === "Escape") {
        cancelPath();
        setShapePreview(null);
        setSelectedIds([]);
        dragRef.current = null;
      }
      if (e.key === "Enter" && drawingPath) {
        e.preventDefault();
        commitPath(tool === "polygon");
      }
      if ((e.key === "Delete" || e.key === "Backspace") && selectedIds.length && !typing) {
        e.preventDefault();
        deleteSelected();
      }
      if ((e.metaKey || e.ctrlKey) && e.key.toLowerCase() === "z") {
        e.preventDefault();
        if (e.shiftKey) redo();
        else undo();
      }
      if (!typing && (e.metaKey || e.ctrlKey)) {
        const k = e.key.toLowerCase();
        if (k === "d") {
          e.preventDefault();
          runDuplicate();
        } else if (k === "c") {
          e.preventDefault();
          runCopy();
        } else if (k === "v") {
          e.preventDefault();
          runPaste();
        } else if (k === "g") {
          e.preventDefault();
          if (e.shiftKey) runUngroup();
          else runGroup();
        }
      }
      if (!typing && !e.metaKey && !e.ctrlKey && !e.altKey) {
        if (e.key === "z" || e.key === "Z") setTool("select");
        if (e.key === "x" || e.key === "X") setTool("rect");
        if (e.key === "c" || e.key === "C") setTool("ellipse");
        if (e.key === "v" || e.key === "V") setTool("line");
        if (e.key === "b" || e.key === "B") setTool("polygon");
        if (e.key === "n" || e.key === "N") setTool("emoji");
        if (e.key === "t" || e.key === "T") setTool("text");
        if (e.key === "m" || e.key === "M") setTool("pan");
        if ((e.key === "u" || e.key === "U") && booleanReady) runUnion();
        if ((e.key === "d" || e.key === "D") && booleanReady) runSubtract();
      }
      if (e.key === "\\" || e.key === "]") {
        e.preventDefault();
        setRightOpen((v) => !v);
      }
    };
    const onKeyUp = (e: KeyboardEvent) => {
      if (e.code === "Space") setSpaceDown(false);
    };
    window.addEventListener("keydown", onKeyDown);
    window.addEventListener("keyup", onKeyUp);
    return () => {
      window.removeEventListener("keydown", onKeyDown);
      window.removeEventListener("keyup", onKeyUp);
    };
  }, [
    drawingPath,
    tool,
    selectedIds,
    commitPath,
    deleteSelected,
    undo,
    redo,
    booleanReady,
    runDuplicate,
    runCopy,
    runPaste,
    runGroup,
    runUngroup,
  ]);

  // Трекпад: два пальца — pan, pinch / ⌃+колесо — zoom к курсору.
  useEffect(() => {
    const el = svgRef.current;
    if (!el) return;
    const onWheel = (e: WheelEvent) => {
      e.preventDefault();
      const { x: panX, y: panY } = panRef.current;
      const z = zoomRef.current;

      if (e.ctrlKey || e.metaKey) {
        const rect = el.getBoundingClientRect();
        const factor = Math.exp(-e.deltaY * 0.01);
        const next = Math.min(4, Math.max(0.25, z * factor));
        if (Math.abs(next - z) < 0.0001) return;
        const mx = e.clientX - rect.left;
        const my = e.clientY - rect.top;
        const worldX = (mx - panX) / z;
        const worldY = (my - panY) / z;
        setZoom(next);
        setPan({ x: mx - worldX * next, y: my - worldY * next });
        return;
      }

      setPan({ x: panX - e.deltaX, y: panY - e.deltaY });
    };
    el.addEventListener("wheel", onWheel, { passive: false });
    return () => el.removeEventListener("wheel", onWheel);
  }, []);

  const switchTool = (next: EditorTool) => {
    if (drawingPath) cancelPath();
    setShapePreview(null);
    setTool(next);
  };

  const onPointerDown = (e: ReactPointerEvent) => {
    if (e.button === 1 || spaceDown || tool === "pan") {
      dragRef.current = {
        mode: "pan",
        startX: e.clientX,
        startY: e.clientY,
        panX: pan.x,
        panY: pan.y,
      };
      (e.currentTarget as Element).setPointerCapture?.(e.pointerId);
      return;
    }

    const p = clientToCanvas(e);

    if (tool === "text") {
      const w = 160;
      const h = 36;
      const id = newNodeId();
      const node: PlanNode = {
        id,
        kind: "text",
        role: "decor",
        label: activeText.trim() || "Текст",
        frame: {
          x: p.x - w / 2,
          y: p.y - h / 2,
          w,
          h,
        },
        style: defaultStyle({ fill: null, stroke: "transparent", strokeWidth: 0 }),
        zIndex: 25,
        bookableId: null,
      };
      pushHistory({ ...plan, nodes: [...plan.nodes, node] });
      setSelectedIds([id]);
      setTool("select");
      return;
    }

    if (tool === "emoji") {
      const size = emojiSize;
      const id = newNodeId();
      const role = placeEmojiDefault ? "bookable" : "decor";
      const node: PlanNode = {
        id,
        kind: "emoji",
        role,
        label: activeEmoji,
        frame: {
          x: p.x - size / 2,
          y: p.y - size / 2,
          w: size,
          h: size,
        },
        style: defaultStyle({ fill: null, stroke: "transparent", strokeWidth: 0 }),
        zIndex: 20,
        bookableId: role === "bookable" ? newNodeId("bk") : null,
      };
      pushHistory({ ...plan, nodes: [...plan.nodes, node] });
      setSelectedIds([id]);
      return;
    }

    if (tool === "line" || tool === "polygon") {
      // Клик у старта при ≥3 точках → замкнуть треугольник / многоугольник
      if (pathPoints.length >= 3) {
        const first = pathPoints[0]!;
        if (dist(p, first) <= screenHitPx(CLOSE_SNAP_PX)) {
          commitPath(true);
          return;
        }
      }
      setPathPoints((pts) => {
        const next = [...pts, p];
        const resolved = resolvePathHover(p, next);
        setHoverPoint(resolved.point);
        setCloseSnap(resolved.snap);
        return next;
      });
      setSelectedIds([]);
      return;
    }

    if (tool === "select") {
      // Ресайз: focus в группе, если выделено несколько
      const resizeNode =
        selectedIds.length === 1
          ? selected
          : focusId
            ? plan.nodes.find((n) => n.id === focusId && n.frame)
            : null;
      if (resizeNode?.frame) {
        const corner = hitTestCorner(resizeNode.frame, p, screenHitPx(HANDLE_HIT_PX));
        if (corner) {
          moveSnapshotRef.current = clonePlan(plan);
          dragRef.current = {
            mode: "resize",
            corner,
            origin: structuredClone(resizeNode),
            lockSquare: resizeNode.kind === "emoji" || e.shiftKey,
          };
          (e.currentTarget as Element).setPointerCapture?.(e.pointerId);
          return;
        }
      }

      const hit = [...plan.nodes].reverse().find((n) => hitTest(n, p));
      if (hit) {
        let nextIds: string[];
        if (e.shiftKey) {
          nextIds = selectedIds.includes(hit.id)
            ? selectedIds.filter((id) => id !== hit.id)
            : [...selectedIds, hit.id];
          setFocusId(hit.id);
        } else {
          // Тап: выделить всю группу, фокус — на кликнутом узле.
          nextIds = expandSelectionWithGroups(plan.nodes, [hit.id]);
          setFocusId(hit.id);
        }
        setSelectedIds(nextIds);
        const origins = plan.nodes
          .filter((n) => nextIds.includes(n.id))
          .map((n) => structuredClone(n));
        moveSnapshotRef.current = clonePlan(plan);
        dragRef.current = { mode: "move", start: p, origins };
        (e.currentTarget as Element).setPointerCapture?.(e.pointerId);
        return;
      }

      if (!e.shiftKey) {
        setSelectedIds([]);
        setFocusId(null);
      }
      dragRef.current = { mode: "marquee", start: p, additive: e.shiftKey };
      setMarquee({ a: p, b: p });
      (e.currentTarget as Element).setPointerCapture?.(e.pointerId);
      return;
    }

    if (tool === "rect" || tool === "ellipse") {
      dragRef.current = { mode: "draw-shape", start: p, shift: e.shiftKey };
      setShapePreview({ a: p, b: p, shift: e.shiftKey });
      setSelectedIds([]);
      (e.currentTarget as Element).setPointerCapture?.(e.pointerId);
    }
  };

  const onPointerMove = (e: ReactPointerEvent) => {
    const p = clientToCanvas(e);
    const drag = dragRef.current;

    if (tool === "line" || tool === "polygon") {
      if (pathPoints.length > 0) {
        const resolved = resolvePathHover(p, pathPoints);
        setHoverPoint(resolved.point);
        setCloseSnap(resolved.snap);
      } else {
        setHoverPoint(p);
        setCloseSnap(false);
      }
    }

    // Курсор на углах стола (даже в группе)
    const cornerNode =
      selectedIds.length === 1
        ? selected
        : focusId
          ? plan.nodes.find((n) => n.id === focusId && n.frame)
          : null;
    if (tool === "select" && !drag && cornerNode?.frame) {
      setHoverCorner(hitTestCorner(cornerNode.frame, p, screenHitPx(HANDLE_HIT_PX)));
    } else if (!drag) {
      setHoverCorner(null);
    }

    if (!drag) return;

    if (drag.mode === "pan") {
      setPan({
        x: drag.panX + (e.clientX - drag.startX),
        y: drag.panY + (e.clientY - drag.startY),
      });
      return;
    }

    if (drag.mode === "marquee") {
      setMarquee({ a: drag.start, b: p });
      return;
    }

    if (drag.mode === "resize" && drag.origin.frame) {
      const lockSquare = drag.lockSquare || e.shiftKey || drag.origin.kind === "emoji";
      const nextFrame = resizeFrame(drag.origin.frame, drag.corner, p, lockSquare);
      const id = drag.origin.id;
      setPlan((prev) => {
        const base = ensurePlan(prev);
        return {
          ...base,
          nodes: base.nodes.map((n) => (n.id === id ? { ...n, frame: nextFrame } : n)),
        };
      });
      return;
    }

    if (drag.mode === "move" && drag.origins.length) {
      const dx = p.x - drag.start.x;
      const dy = p.y - drag.start.y;
      const byId = new Map(drag.origins.map((o) => [o.id, o]));
      setPlan((prev) => {
        const base = ensurePlan(prev);
        return {
          ...base,
          nodes: base.nodes.map((n) => {
            const origin = byId.get(n.id);
            if (!origin) return n;
            return translateNode(origin, dx, dy);
          }),
        };
      });
      return;
    }

    if (drag.mode === "draw-shape") {
      setShapePreview({ a: drag.start, b: p, shift: e.shiftKey || drag.shift });
    }
  };

  const onPointerUp = (e: ReactPointerEvent) => {
    const drag = dragRef.current;
    const p = clientToCanvas(e);
    dragRef.current = null;

    if (drag?.mode === "pan") return;

    if (drag?.mode === "marquee") {
      setMarquee(null);
      const x = Math.min(drag.start.x, p.x);
      const y = Math.min(drag.start.y, p.y);
      const w = Math.abs(p.x - drag.start.x);
      const h = Math.abs(p.y - drag.start.y);
      if (w < screenHitPx(CLICK_THRESHOLD) && h < screenHitPx(CLICK_THRESHOLD)) {
        return;
      }
      const box = { x, y, w, h };
      const hitIds = ensurePlan(planRef.current).nodes
        .filter((n) => {
          const b = nodeBounds(n);
          return b ? boundsIntersect(box, b) : false;
        })
        .map((n) => n.id);
      setSelectedIds((prev) =>
        drag.additive ? [...new Set([...prev, ...hitIds])] : hitIds,
      );
      return;
    }

    if (drag?.mode === "move" || drag?.mode === "resize") {
      const snapshot = moveSnapshotRef.current;
      moveSnapshotRef.current = null;
      if (snapshot) {
        setHistory((h) => [...h.slice(-50), clonePlan(ensurePlan(snapshot))]);
        setFuture([]);
      }
      return;
    }

    if (drag?.mode === "draw-shape" && (tool === "rect" || tool === "ellipse")) {
      const shift = e.shiftKey || drag.shift;
      let frame: { x: number; y: number; w: number; h: number };
      if (dist(drag.start, p) < screenHitPx(CLICK_THRESHOLD)) {
        const size = tool === "ellipse" ? DEFAULT_ELLIPSE : DEFAULT_RECT;
        frame = {
          x: drag.start.x - size.w / 2,
          y: drag.start.y - size.h / 2,
          w: size.w,
          h: size.h,
        };
      } else {
        frame = normalizeFrame(drag.start, p, shift);
      }
      const node = makeShapeNode(tool, frame);
      pushHistory({ ...plan, nodes: [...plan.nodes, node] });
      setSelectedIds([node.id]);
      setShapePreview(null);
      return;
    }

    setShapePreview(null);
  };

  const onDoubleClick = () => {
    if (tool === "line") commitPath(false);
    if (tool === "polygon") commitPath(true);
  };

  const tools: {
    id: EditorTool;
    label: string;
    hint: string;
    help: string;
    Icon: typeof Square;
  }[] = [
    {
      id: "select",
      label: "Выбор",
      hint: "Z",
      help: "Клик — выбрать · рамка — несколько · Shift — добавить",
      Icon: MousePointer2,
    },
    {
      id: "rect",
      label: "Стол",
      hint: "X",
      help: "Потяни на плане — прямоугольный стол или зона",
      Icon: Square,
    },
    {
      id: "ellipse",
      label: "Овал",
      hint: "C",
      help: "Круглый стол · зажми Shift — идеальный круг",
      Icon: Circle,
    },
    {
      id: "line",
      label: "Линия",
      hint: "V",
      help: "Кликай точки · к началу — замкнуть · Enter — готово",
      Icon: Minus,
    },
    {
      id: "polygon",
      label: "Фигура",
      hint: "B",
      help: "Многоугольник из вершин · замкни у первой точки",
      Icon: Hexagon,
    },
    {
      id: "emoji",
      label: "Смайл",
      hint: "N",
      help: "Стулья, растения, указатели — клик по плану",
      Icon: Smile,
    },
    {
      id: "text",
      label: "Текст",
      hint: "T",
      help: "Подпись на плане («VIP», «Кухня»…)",
      Icon: Type,
    },
    {
      id: "pan",
      label: "Рука",
      hint: "M",
      help: "Двигай холст · или два пальца на трекпаде",
      Icon: Hand,
    },
  ];

  const activeTool = tools.find((t) => t.id === tool) ?? tools[0]!;
  const contextHint = useMemo(() => {
    if (drawingPath) {
      return closeSnap
        ? "Можно замкнуть — клик по первой точке или Enter"
        : "Добавляй точки · к началу линии — замкнуть фигуру";
    }
    if (selectedNodes.length > 1) {
      return `Выделено ${selectedNodes.length}`;
    }
    if (selectedNodes.length === 1) {
      const n = selectedNodes[0]!;
      const kindRu =
        n.kind === "emoji"
          ? "смайлик"
          : n.kind === "text"
            ? "текст"
            : n.kind === "rect"
              ? "стол/зона"
              : n.kind === "ellipse"
                ? "овал"
                : n.kind === "polygon"
                  ? "фигура"
                  : "линия";
      if (n.kind === "rect" || n.kind === "ellipse" || n.kind === "polygon") {
        return `${n.label || kindRu} · свойства справа`;
      }
      return `${n.label || kindRu}`;
    }
    return activeTool.help;
  }, [drawingPath, closeSnap, selectedNodes, booleanReady, activeTool.help]);

  const rotationValue = useMemo(() => {
    if (!selectedNodes.length) return 0;
    const first = selectedNodes[0]?.rotation ?? 0;
    return selectedNodes.every((n) => (n.rotation ?? 0) === first) ? first : 0;
  }, [selectedNodes]);

  const pathPreviewPoints = useMemo(() => {
    if (!pathPoints.length) return "";
    if (closeSnap && pathPoints[0]) {
      return [...pathPoints, pathPoints[0]].map((pt) => `${pt.x},${pt.y}`).join(" ");
    }
    const tip = hoverPoint ?? pathPoints[pathPoints.length - 1]!;
    return [...pathPoints, tip].map((pt) => `${pt.x},${pt.y}`).join(" ");
  }, [pathPoints, hoverPoint, closeSnap]);

  if (!plan?.nodes) {
    return <div className="fixed inset-0 z-[80] bg-bg" />;
  }

  return (
    <div className="fixed inset-0 z-[80] flex flex-col bg-bg">
      <header className="flex h-12 shrink-0 items-center gap-1 border-b border-line bg-surface px-2.5">
        <TipBtn tip="Назад" side="bottom">
          <Link
            href={backHref ?? `/app/settings/venue/v/${venueId}`}
            className="flex h-9 w-9 items-center justify-center rounded-[10px] text-svc-venue-ink transition hover:bg-svc-venue"
            aria-label="Назад"
          >
            <ArrowLeft className="h-5 w-5" strokeWidth={2} />
          </Link>
        </TipBtn>
        <div className="min-w-0 flex-1 px-1">
          <p className="truncate text-[14px] font-bold text-ink">{venueName ?? plan.label}</p>
          <p className="truncate text-[11px] text-muted">
            {plan.label || "Этаж"} · {plan.nodes.length} · {Math.round(zoom * 100)}%
          </p>
        </div>

        <TipBtn tip="Отменить" detail="⌘Z" side="bottom" onClick={undo}>
          <Undo2 className="h-4 w-4" />
        </TipBtn>
        <TipBtn tip="Повторить" detail="⌘⇧Z" side="bottom" onClick={redo}>
          <Redo2 className="h-4 w-4" />
        </TipBtn>
        <TipBtn
          tip={snapOn ? "Сетка вкл" : "Сетка выкл"}
          side="bottom"
          active={snapOn}
          onClick={() => setSnapOn((v) => !v)}
        >
          <Magnet className="h-4 w-4" />
        </TipBtn>
        <TipBtn tip="Сохранить" detail="Черновик" side="bottom" onClick={saveDraftNow}>
          <Save className="h-4 w-4" />
        </TipBtn>

        <div className="relative">
          <TipBtn
            tip="Ещё"
            detail="Скачать · открыть · JSON · шаблоны"
            side="bottom"
            active={fileMenuOpen}
            onClick={() => setFileMenuOpen((v) => !v)}
          >
            <MoreHorizontal className="h-4 w-4" />
          </TipBtn>
          {fileMenuOpen ? (
            <>
              <button
                type="button"
                className="fixed inset-0 z-[85] cursor-default"
                aria-label="Закрыть меню"
                onClick={() => setFileMenuOpen(false)}
              />
              <div className="absolute right-0 top-full z-[86] mt-1 w-52 rounded-[14px] border border-line bg-surface p-1.5 shadow-elevate-md">
                <button
                  type="button"
                  className="flex w-full items-center gap-2 rounded-[10px] px-2.5 py-2 text-left text-[13px] font-semibold text-ink hover:bg-surface-soft"
                  onClick={() => {
                    setFileMenuOpen(false);
                    downloadBuilding();
                  }}
                >
                  <Download className="h-4 w-4 text-muted" />
                  Скачать JSON
                </button>
                <button
                  type="button"
                  className="flex w-full items-center gap-2 rounded-[10px] px-2.5 py-2 text-left text-[13px] font-semibold text-ink hover:bg-surface-soft"
                  onClick={() => {
                    setFileMenuOpen(false);
                    fileInputRef.current?.click();
                  }}
                >
                  <FolderOpen className="h-4 w-4 text-muted" />
                  Открыть файл
                </button>
                <button
                  type="button"
                  className="flex w-full items-center gap-2 rounded-[10px] px-2.5 py-2 text-left text-[13px] font-semibold text-ink hover:bg-surface-soft"
                  onClick={() => {
                    setFileMenuOpen(false);
                    setJsonPasteError(null);
                    setJsonPasteOpen(true);
                  }}
                >
                  <Braces className="h-4 w-4 text-muted" />
                  Вставить JSON
                </button>
                <div className="my-1 h-px bg-line" />
                <button
                  type="button"
                  className="flex w-full items-center gap-2 rounded-[10px] px-2.5 py-2 text-left text-[13px] font-semibold text-ink hover:bg-surface-soft"
                  onClick={() => {
                    setFileMenuOpen(false);
                    applyBuilding(createCafeBuilding());
                  }}
                >
                  Шаблон: кафе
                </button>
                <button
                  type="button"
                  className="flex w-full items-center gap-2 rounded-[10px] px-2.5 py-2 text-left text-[13px] font-semibold text-ink hover:bg-surface-soft"
                  onClick={() => {
                    setFileMenuOpen(false);
                    applyBuilding(buildingFromPlan(createCinemaStarterPlan()));
                  }}
                >
                  Шаблон: кино
                </button>
                <button
                  type="button"
                  className="flex w-full items-center gap-2 rounded-[10px] px-2.5 py-2 text-left text-[13px] font-semibold text-ink hover:bg-surface-soft"
                  onClick={() => {
                    setFileMenuOpen(false);
                    applyBuilding(PLAN_CRAZY_EMOJI_BUILDING);
                  }}
                >
                  Шаблон: emoji chaos
                </button>
                <button
                  type="button"
                  className="flex w-full items-center gap-2 rounded-[10px] px-2.5 py-2 text-left text-[13px] font-semibold text-ink hover:bg-surface-soft"
                  onClick={() => {
                    setFileMenuOpen(false);
                    applyBuilding(buildingFromPlan(createBanquetStarterPlan()));
                  }}
                >
                  Шаблон: банкет
                </button>
                <button
                  type="button"
                  className="flex w-full items-center gap-2 rounded-[10px] px-2.5 py-2 text-left text-[13px] font-semibold text-ink hover:bg-surface-soft"
                  onClick={() => {
                    setFileMenuOpen(false);
                    applyBuilding(buildingFromPlan(createEmptyPlan()));
                  }}
                >
                  Новый лист
                </button>
              </div>
            </>
          ) : null}
        </div>

        <input
          ref={fileInputRef}
          type="file"
          accept="application/json,.json"
          className="hidden"
          onChange={(e) => {
            void openPlanFile(e.target.files?.[0]);
            e.target.value = "";
          }}
        />

        {jsonPasteOpen ? (
          <div className="fixed inset-0 z-[90] flex items-center justify-center bg-black/45 p-4">
            <div
              role="dialog"
              aria-modal="true"
              aria-label="Вставить JSON плана"
              className="flex max-h-[min(88vh,720px)] w-full max-w-2xl flex-col rounded-[20px] border border-line bg-surface shadow-elevate"
            >
              <div className="border-b border-line px-4 py-3">
                <p className="text-[15px] font-bold text-ink">Вставить JSON плана</p>
                <p className="mt-1 text-[12px] leading-snug text-muted">
                  Вставьте JSON или подставьте пример — затем «Применить».
                </p>
                <div className="mt-2 flex flex-wrap gap-2">
                  <AppButton
                    service="venue"
                    size="row"
                    variant="outline"
                    onClick={() => {
                      setJsonPasteText(planFullExampleJson());
                      setJsonPasteError(null);
                    }}
                  >
                    Полный пример
                  </AppButton>
                  <AppButton
                    service="venue"
                    size="row"
                    variant="outline"
                    onClick={() => {
                      setJsonPasteText(planCrazyEmojiJson());
                      setJsonPasteError(null);
                    }}
                  >
                    Emoji chaos
                  </AppButton>
                  <AppButton
                    size="row"
                    variant="ghost"
                    onClick={() => {
                      void navigator.clipboard.writeText(
                        `${PLAN_JSON_AI_HINT}\n\n${planFullExampleJson()}`,
                      );
                    }}
                  >
                    Копировать + AI
                  </AppButton>
                </div>
              </div>
              <textarea
                value={jsonPasteText}
                onChange={(e) => {
                  setJsonPasteText(e.target.value);
                  setJsonPasteError(null);
                }}
                spellCheck={false}
                placeholder="Вставьте JSON…"
                className="min-h-[260px] flex-1 resize-y bg-bg px-4 py-3 font-mono text-[12px] leading-relaxed text-ink outline-none"
              />
              {jsonPasteError ? (
                <p className="px-4 pb-2 text-[12px] font-semibold text-destructive">{jsonPasteError}</p>
              ) : null}
              <div className="flex flex-wrap gap-2 border-t border-line px-4 py-3">
                <AppButton
                  service="venue"
                  size="row"
                  className="gap-1.5"
                  onClick={applyPastedJson}
                  disabled={!jsonPasteText.trim()}
                >
                  Применить
                </AppButton>
                <AppButton
                  variant="outline"
                  size="row"
                  onClick={() => {
                    setJsonPasteOpen(false);
                    setJsonPasteError(null);
                  }}
                >
                  Отмена
                </AppButton>
              </div>
            </div>
          </div>
        ) : null}

        <TipBtn
          tip={rightOpen ? "Скрыть панель" : "Свойства"}
          side="bottom"
          onClick={() => setRightOpen((v) => !v)}
        >
          {rightOpen ? <PanelRightClose className="h-4 w-4" /> : <PanelRightOpen className="h-4 w-4" />}
        </TipBtn>
      </header>

      <div className="flex shrink-0 items-center gap-1 overflow-x-auto border-b border-line bg-surface px-3 py-1.5">
        <span className="mr-1 shrink-0 text-[9px] font-bold uppercase tracking-wide text-muted">
          Этажи
        </span>
        {sortFloors(floors).map((floor) => {
          const active = floor.floorKey === plan.floorKey;
          return (
            <div key={floor.floorKey} className="flex shrink-0 items-center gap-0.5">
              <TipBtn
                tip={floor.label || "Этаж"}
                detail="Переключить этаж — у каждого свой план"
                side="bottom"
                active={active}
                onClick={() => switchFloor(floor.floorKey)}
                className="h-8 max-w-[160px] rounded-full px-3 text-[12px] font-semibold"
              >
                <span
                  className="truncate"
                  onDoubleClick={(e) => {
                    e.preventDefault();
                    e.stopPropagation();
                    renameFloor(floor.floorKey);
                  }}
                >
                  {floor.label || "Этаж"}
                </span>
              </TipBtn>
              <TipBtn
                tip="Переименовать"
                detail="Название этажа (ключ этажа не меняется)"
                side="bottom"
                onClick={() => renameFloor(floor.floorKey)}
                className="h-7 w-7 rounded-full"
              >
                <Pencil className="h-3 w-3" />
              </TipBtn>
              {floors.length > 1 ? (
                <TipBtn
                  tip="Удалить этаж"
                  detail="Только если этажей больше одного"
                  side="bottom"
                  onClick={() => deleteFloor(floor.floorKey)}
                  className="h-7 w-7 rounded-full"
                >
                  <Trash2 className="h-3 w-3" />
                </TipBtn>
              ) : null}
            </div>
          );
        })}
        <TipBtn
          tip="Новый этаж"
          detail="Добавить пустой этаж и переключиться на него"
          side="bottom"
          onClick={addFloor}
          className="h-8 shrink-0 gap-1 rounded-full px-3 text-[12px] font-semibold"
        >
          <Plus className="h-3.5 w-3.5" />
          <span>этаж</span>
        </TipBtn>
      </div>

      <div className="relative flex min-h-0 flex-1">
        <aside className="z-20 flex w-14 shrink-0 flex-col items-center gap-0.5 overflow-y-auto border-r border-line bg-surface py-2">
          {tools.map(({ id, label, hint, help, Icon }) => {
            const active = tool === id;
            return (
              <TipBtn
                key={id}
                tip={label}
                detail={`${help} · ${hint}`}
                side="right"
                active={active}
                onClick={() => switchTool(id)}
                className="h-10 w-10 rounded-[12px]"
              >
                <Icon className="h-[18px] w-[18px]" strokeWidth={2} />
              </TipBtn>
            );
          })}
          <div className="my-1 h-px w-8 bg-line" />
          <TipBtn tip="Группа" detail="⌘G" side="right" onClick={runGroup} disabled={selectedIds.length < 2}>
            <Group className="h-4 w-4" />
          </TipBtn>
          <TipBtn tip="Связать emoji" side="right" onClick={() => runLinkEmojis()} disabled={!canLinkEmojis}>
            <Link2 className="h-4 w-4" />
          </TipBtn>
          <TipBtn tip="Разгруппировать" detail="⌘⇧G" side="right" onClick={runUngroup} disabled={!selectedIds.length}>
            <Ungroup className="h-4 w-4" />
          </TipBtn>
          <TipBtn tip="Дублировать" detail="⌘D" side="right" onClick={runDuplicate} disabled={!selectedIds.length}>
            <Copy className="h-4 w-4" />
          </TipBtn>
          <TipBtn tip="Удалить" detail="Delete" side="right" onClick={deleteSelected} disabled={!selectedIds.length}>
            <Trash2 className="h-4 w-4" />
          </TipBtn>
          <div className="relative">
            <TipBtn
              tip="Ещё правки"
              detail="Объединить · вычесть · очистить"
              side="right"
              active={editMoreOpen}
              onClick={() => setEditMoreOpen((v) => !v)}
            >
              <MoreHorizontal className="h-4 w-4" />
            </TipBtn>
            {editMoreOpen ? (
              <>
                <button
                  type="button"
                  className="fixed inset-0 z-[85] cursor-default"
                  aria-label="Закрыть"
                  onClick={() => setEditMoreOpen(false)}
                />
                <div className="absolute left-full top-0 z-[86] ml-2 w-44 rounded-[14px] border border-line bg-surface p-1.5 shadow-elevate-md">
                  <button
                    type="button"
                    disabled={!booleanReady}
                    className="flex w-full items-center gap-2 rounded-[10px] px-2.5 py-2 text-left text-[13px] font-semibold text-ink hover:bg-surface-soft disabled:opacity-30"
                    onClick={() => {
                      setEditMoreOpen(false);
                      runUnion();
                    }}
                  >
                    <Combine className="h-4 w-4 text-muted" />
                    Объединить
                  </button>
                  <button
                    type="button"
                    disabled={!booleanReady}
                    className="flex w-full items-center gap-2 rounded-[10px] px-2.5 py-2 text-left text-[13px] font-semibold text-ink hover:bg-surface-soft disabled:opacity-30"
                    onClick={() => {
                      setEditMoreOpen(false);
                      runSubtract();
                    }}
                  >
                    <SplitSquareVertical className="h-4 w-4 text-muted" />
                    Вычесть
                  </button>
                  <button
                    type="button"
                    className="flex w-full items-center gap-2 rounded-[10px] px-2.5 py-2 text-left text-[13px] font-semibold text-ink hover:bg-surface-soft"
                    onClick={() => {
                      setEditMoreOpen(false);
                      cancelPath();
                      pushHistory({ ...plan, nodes: [] });
                      setSelectedIds([]);
                    }}
                  >
                    <Eraser className="h-4 w-4 text-muted" />
                    Очистить лист
                  </button>
                </div>
              </>
            ) : null}
          </div>
        </aside>

        <div
          className="relative min-w-0 flex-1 overscroll-none"
          style={{ background: plan.canvas.background }}
        >
          <svg
            ref={svgRef}
            className="h-full w-full touch-none"
            style={{
              cursor:
                spaceDown || tool === "pan"
                  ? "grab"
                  : hoverCorner
                    ? cornerCursor(hoverCorner)
                    : cursorFor(tool, drawingPath),
            }}
            onPointerDown={onPointerDown}
            onPointerMove={onPointerMove}
            onPointerUp={onPointerUp}
            onDoubleClick={onDoubleClick}
          >
            <defs>
              <filter id="nodeShadow" x="-20%" y="-20%" width="140%" height="140%">
                <feDropShadow dx="0" dy="2" stdDeviation="3" floodOpacity="0.12" />
              </filter>
              {snapOn && (
                <pattern
                  id="planGrid"
                  width={PLAN_GRID}
                  height={PLAN_GRID}
                  patternUnits="userSpaceOnUse"
                >
                  <path
                    d={`M ${PLAN_GRID} 0 L 0 0 0 ${PLAN_GRID}`}
                    fill="none"
                    stroke="#B54B45"
                    strokeWidth={0.5}
                    opacity={0.18}
                  />
                </pattern>
              )}
            </defs>
            <g transform={`translate(${pan.x} ${pan.y}) scale(${zoom})`}>
              {snapOn && (
                <rect
                  x={-2000}
                  y={-2000}
                  width={6000}
                  height={6000}
                  fill="url(#planGrid)"
                  style={{ pointerEvents: "none" }}
                />
              )}
              {emojiGroupHulls.map(({ gid, bounds, centers }) => (
                <g key={`hull_${gid}`} style={{ pointerEvents: "none" }}>
                  <rect
                    x={bounds.x}
                    y={bounds.y}
                    width={bounds.w}
                    height={bounds.h}
                    rx={14}
                    fill="color-mix(in srgb, #C5FEB7 18%, transparent)"
                    stroke="#1A5C2E"
                    strokeWidth={1.5}
                    strokeDasharray="6 4"
                    opacity={0.85}
                  />
                  {centers.length >= 2
                    ? centers.slice(0, -1).map((a, i) => {
                        const b = centers[i + 1]!;
                        return (
                          <line
                            key={`${gid}_l_${i}`}
                            x1={a.x}
                            y1={a.y}
                            x2={b.x}
                            y2={b.y}
                            stroke="#1A5C2E"
                            strokeWidth={1.25}
                            strokeDasharray="3 3"
                            opacity={0.45}
                          />
                        );
                      })
                    : null}
                </g>
              ))}
              {[...plan.nodes]
                .sort((a, b) => a.zIndex - b.zIndex)
                .map((node) => (
                  <PlanNodeShape
                    key={node.id}
                    node={node}
                    selected={selectedIds.includes(node.id)}
                    guestDim={false}
                  />
                ))}
              {pathPoints.length > 0 && (
                <>
                  {tool === "polygon" || closeSnap ? (
                    <polygon
                      points={pathPreviewPoints}
                      fill="color-mix(in srgb, #FFA39E 28%, transparent)"
                      stroke="#B54B45"
                      strokeWidth={2}
                      strokeDasharray={closeSnap ? undefined : "5 4"}
                    />
                  ) : (
                    <polyline
                      points={pathPreviewPoints}
                      fill="none"
                      stroke="#B54B45"
                      strokeWidth={2.5}
                      strokeLinecap="round"
                      strokeLinejoin="round"
                    />
                  )}
                  {pathPoints.map((pt, i) => (
                    <circle
                      key={i}
                      cx={pt.x}
                      cy={pt.y}
                      r={i === 0 ? (closeSnap ? 7 : 5) : 4}
                      fill={i === 0 ? "#FFA39E" : "#fff"}
                      stroke="#B54B45"
                      strokeWidth={1.5}
                    />
                  ))}
                  {pathPoints[0] && pathPoints.length >= 3 && (
                    <g>
                      <circle
                        cx={pathPoints[0].x}
                        cy={pathPoints[0].y}
                        r={CLOSE_SNAP_PX}
                        fill="none"
                        stroke="#B54B45"
                        strokeWidth={closeSnap ? 2 : 1}
                        strokeDasharray={closeSnap ? undefined : "4 3"}
                        opacity={closeSnap ? 0.9 : 0.35}
                      />
                      {closeSnap && (
                        <>
                          <circle
                            cx={pathPoints[0].x}
                            cy={pathPoints[0].y}
                            r={14}
                            fill="color-mix(in srgb, #FFA39E 45%, transparent)"
                            stroke="#B54B45"
                            strokeWidth={2}
                          />
                          <text
                            x={pathPoints[0].x}
                            y={pathPoints[0].y - 28}
                            textAnchor="middle"
                            fill="#B54B45"
                            fontSize={12}
                            fontWeight={700}
                            style={{ fontFamily: "var(--font-manrope), sans-serif" }}
                          >
                            Замкнуть
                          </text>
                        </>
                      )}
                    </g>
                  )}
                </>
              )}
              {shapePreview && (tool === "rect" || tool === "ellipse") && (
                <DraftShape
                  tool={tool}
                  a={shapePreview.a}
                  b={shapePreview.b}
                  shift={shapePreview.shift}
                  fill={fill}
                  stroke={stroke}
                />
              )}
              {marquee && (
                <rect
                  x={Math.min(marquee.a.x, marquee.b.x)}
                  y={Math.min(marquee.a.y, marquee.b.y)}
                  width={Math.abs(marquee.b.x - marquee.a.x)}
                  height={Math.abs(marquee.b.y - marquee.a.y)}
                  fill="color-mix(in srgb, #FFA39E 18%, transparent)"
                  stroke="#B54B45"
                  strokeWidth={1.5 / zoom}
                  strokeDasharray={`${6 / zoom} ${4 / zoom}`}
                />
              )}
            </g>
          </svg>

          <div className="pointer-events-none absolute inset-x-0 bottom-0 z-10 flex justify-center p-2.5">
            <div className="max-w-[min(480px,92%)] rounded-[12px] border border-line bg-surface/95 px-3 py-1.5 text-center shadow-elevate-sm backdrop-blur">
              <p className="text-[12px] font-medium text-ink">
                <span className="font-bold text-svc-venue-ink">{activeTool.label}</span>
                <span className="text-muted"> · </span>
                {contextHint}
              </p>
            </div>
          </div>

          {!rightOpen && (
            <TipBtn
              tip="Свойства"
              detail="Цвета, фон, пресеты залов"
              side="left"
              className="absolute right-3 top-3 z-20 h-10 w-10 rounded-[14px] border border-line bg-surface shadow-elevate-md"
              onClick={() => setRightOpen(true)}
            >
              <PanelRightOpen className="h-4 w-4 text-svc-venue-ink" />
            </TipBtn>
          )}
        </div>

        <aside
          className={`flex shrink-0 flex-col overflow-hidden border-l border-line bg-surface shadow-elevate-md transition-[width] duration-200 ease-out ${
            rightOpen ? "w-[280px]" : "w-0 border-l-0"
          }`}
        >
          <div className="flex h-full w-[280px] flex-col gap-3 overflow-y-auto p-3">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-[11px] font-bold uppercase tracking-wide text-muted">Свойства</p>
                <p className="text-[12px] text-muted">Цвет и объекты</p>
              </div>
              <TipBtn tip="Скрыть панель" detail="Клавиша ]" side="left" onClick={() => setRightOpen(false)}>
                <PanelRightClose className="h-4 w-4" />
              </TipBtn>
            </div>

            {selected?.kind === "emoji" ? (
              <div className="flex gap-1.5">
                <button
                  type="button"
                  className={`flex-1 rounded-[12px] border px-2 py-2 text-[12px] font-bold ${
                    selectedNodes.filter((n) => n.kind === "emoji").every((n) => n.role === "bookable")
                      ? "border-svc-venue-ink bg-svc-venue text-ink"
                      : "border-line bg-surface text-muted"
                  }`}
                  onClick={() => {
                    const ids = new Set(selectedNodes.filter((n) => n.kind === "emoji").map((n) => n.id));
                    pushHistory({
                      ...planRef.current,
                      nodes: planRef.current.nodes.map((n) =>
                        ids.has(n.id)
                          ? { ...n, role: "bookable", bookableId: n.bookableId ?? newNodeId("bk") }
                          : n,
                      ),
                    });
                  }}
                >
                  Место
                </button>
                <button
                  type="button"
                  className={`flex-1 rounded-[12px] border px-2 py-2 text-[12px] font-bold ${
                    selectedNodes.filter((n) => n.kind === "emoji").every((n) => n.role === "decor")
                      ? "border-svc-venue-ink bg-svc-venue text-ink"
                      : "border-line bg-surface text-muted"
                  }`}
                  onClick={() => {
                    const ids = new Set(selectedNodes.filter((n) => n.kind === "emoji").map((n) => n.id));
                    pushHistory({
                      ...planRef.current,
                      nodes: planRef.current.nodes.map((n) =>
                        ids.has(n.id) ? { ...n, role: "decor", bookableId: null } : n,
                      ),
                    });
                  }}
                >
                  Декор
                </button>
              </div>
            ) : null}

            <section>
              <p className="mb-2 text-[11px] font-bold uppercase tracking-wide text-muted">Фон</p>
              <ColorRow
                value={plan.canvas.background}
                presets={VENUE_FILL_PRESETS}
                onChange={applyCanvasBackground}
              />
            </section>

            <div className="h-px bg-line" />

            {tool === "text" && !selected ? (
              <section>
                <p className="mb-2 text-[11px] font-bold uppercase tracking-wide text-muted">Текст</p>
                <input
                  value={activeText}
                  onChange={(e) => setActiveText(e.target.value)}
                  placeholder="Текст"
                  className="w-full rounded-[14px] border border-border-input bg-bg px-3 py-2.5 text-[14px] text-ink outline-none focus:border-svc-venue-ink"
                />
                <p className="mt-2 text-[12px] leading-relaxed text-muted">
                  Клик по плану вставит подпись.
                </p>
              </section>
            ) : tool === "emoji" || selected?.kind === "emoji" ? (
              <section className="space-y-3">
                <p className="text-[11px] font-bold uppercase tracking-wide text-muted">Смайлик</p>
                <div className="max-h-[200px] grid grid-cols-6 gap-1 overflow-y-auto pr-0.5">
                  {VENUE_EMOJI_PRESETS.map((emo) => {
                    const active =
                      selected?.kind === "emoji" ? selected.label === emo : activeEmoji === emo;
                    return (
                      <button
                        key={emo}
                        type="button"
                        title={emo}
                        onClick={() => {
                          setActiveEmoji(emo);
                          if (selected?.kind === "emoji") updateSelected({ label: emo });
                          else setTool("emoji");
                        }}
                        className={`flex h-9 items-center justify-center rounded-[10px] text-[20px] transition ${
                          active
                            ? "bg-svc-venue ring-2 ring-svc-venue-ink/40"
                            : "bg-surface-soft hover:bg-svc-venue/50"
                        }`}
                      >
                        {emo}
                      </button>
                    );
                  })}
                </div>
                <label className="flex items-center justify-between text-[12px] font-semibold text-ink">
                  Размер
                  <span className="text-muted">
                    {selected?.kind === "emoji" && selected.frame
                      ? Math.round(selected.frame.w)
                      : emojiSize}
                  </span>
                </label>
                <input
                  type="range"
                  min={32}
                  max={400}
                  value={
                    selected?.kind === "emoji" && selected.frame ? selected.frame.w : emojiSize
                  }
                  onChange={(e) => {
                    const size = Number(e.target.value);
                    setEmojiSize(size);
                    if (selected?.kind === "emoji" && selected.frame) {
                      const cx = selected.frame.x + selected.frame.w / 2;
                      const cy = selected.frame.y + selected.frame.h / 2;
                      updateSelected({
                        frame: { x: cx - size / 2, y: cy - size / 2, w: size, h: size },
                      });
                    }
                  }}
                  className="w-full accent-[var(--svc-venue-ink)]"
                />
                <div className="flex gap-1.5">
                  <button
                    type="button"
                    className={`flex-1 rounded-[12px] border px-2 py-2 text-[12px] font-bold ${
                      placeEmojiDefault
                        ? "border-svc-venue-ink bg-svc-venue text-ink"
                        : "border-line bg-surface text-muted"
                    }`}
                    onClick={() => setPlaceEmojiDefault(true)}
                  >
                    Место
                  </button>
                  <button
                    type="button"
                    className={`flex-1 rounded-[12px] border px-2 py-2 text-[12px] font-bold ${
                      !placeEmojiDefault
                        ? "border-svc-venue-ink bg-svc-venue text-ink"
                        : "border-line bg-surface text-muted"
                    }`}
                    onClick={() => setPlaceEmojiDefault(false)}
                  >
                    Декор
                  </button>
                </div>
                <div className="space-y-2 rounded-[12px] border border-line bg-surface-soft/50 p-2.5">
                  <div className="flex flex-wrap gap-1">
                    {(
                      [
                        ["row", "Ряд"],
                        ["arc", "Дуга"],
                        ["grid", "Сетка"],
                        ["pair", "Пара"],
                      ] as const
                    ).map(([id, label]) => (
                      <button
                        key={id}
                        type="button"
                        onClick={() => setClusterLayout(id)}
                        className={`rounded-[8px] border px-2 py-1 text-[11px] font-bold ${
                          clusterLayout === id
                            ? "border-svc-venue-ink bg-svc-venue text-ink"
                            : "border-line bg-surface text-muted"
                        }`}
                      >
                        {label}
                      </button>
                    ))}
                  </div>
                  <label className="flex items-center justify-between text-[12px] font-semibold text-ink">
                    Связка
                    <span className="text-muted">×{clusterCount}</span>
                  </label>
                  <input
                    type="range"
                    min={2}
                    max={6}
                    value={clusterCount}
                    onChange={(e) => setClusterCount(Number(e.target.value))}
                    className="w-full accent-[var(--svc-venue-ink)]"
                  />
                  <AppButton
                    type="button"
                    service="venue"
                    size="row"
                    className="w-full gap-1.5"
                    onClick={() => insertEmojiCluster()}
                  >
                    <LayoutGrid className="h-3.5 w-3.5" />
                    Вставить {activeEmoji}×{clusterCount}
                  </AppButton>
                  {canLinkEmojis ? (
                    <AppButton
                      type="button"
                      service="venue"
                      variant="outline"
                      size="row"
                      className="w-full gap-1.5"
                      onClick={() => runLinkEmojis()}
                    >
                      <Link2 className="h-3.5 w-3.5" />
                      Связать ({selectedEmojis.length})
                    </AppButton>
                  ) : null}
                </div>
              </section>
            ) : (
              <section>
                <p className="mb-2 text-[11px] font-bold uppercase tracking-wide text-muted">
                  {selectedNodes.length > 1
                    ? `Цвет · ${selectedNodes.length} объектов`
                    : selected
                      ? "Цвет объекта"
                      : "Цвет"}
                </p>
                <p className="mb-1.5 text-[12px] font-semibold text-ink">Заливка</p>
                <ColorRow value={fill} presets={VENUE_FILL_PRESETS} onChange={applyFill} />
                <p className="mb-1.5 mt-3 text-[12px] font-semibold text-ink">Обводка</p>
                <ColorRow value={stroke} presets={VENUE_STROKE_PRESETS} onChange={applyStroke} />
                <label className="mt-3 flex items-center justify-between text-[13px] font-semibold text-ink">
                  Толщина
                  <span className="text-muted">{strokeWidth}</span>
                </label>
                <input
                  type="range"
                  min={1}
                  max={10}
                  value={strokeWidth}
                  onChange={(e) => applyStrokeWidth(Number(e.target.value))}
                  className="mt-1 w-full accent-[var(--svc-venue-ink)]"
                />
                {!selectedNodes.length || selectedNodes.some((n) => n.kind === "rect") ? (
                  <>
                    <label className="mt-3 flex items-center justify-between text-[13px] font-semibold text-ink">
                      Радиус
                      <span className="text-muted">
                        {selected?.kind === "rect" && selected.frame
                          ? Math.min(
                              radius,
                              Math.round(Math.min(selected.frame.w, selected.frame.h) / 2),
                            )
                          : radius}
                      </span>
                    </label>
                    <input
                      type="range"
                      min={0}
                      max={
                        selected?.kind === "rect" && selected.frame
                          ? Math.max(
                              0,
                              Math.round(Math.min(selected.frame.w, selected.frame.h) / 2),
                            )
                          : 80
                      }
                      value={
                        selected?.kind === "rect" && selected.frame
                          ? Math.min(
                              radius,
                              Math.round(Math.min(selected.frame.w, selected.frame.h) / 2),
                            )
                          : radius
                      }
                      onChange={(e) => applyRadius(Number(e.target.value))}
                      className="mt-1 w-full accent-[var(--svc-venue-ink)]"
                    />
                  </>
                ) : null}
              </section>
            )}

            {selectedNodes.length > 0 ? (
              <section>
                <label className="flex items-center justify-between text-[13px] font-semibold text-ink">
                  Поворот
                  <span className="text-muted">{Math.round(rotationValue)}°</span>
                </label>
                <input
                  type="range"
                  min={0}
                  max={360}
                  value={rotationValue}
                  onChange={(e) => updateSelected({ rotation: Number(e.target.value) })}
                  className="mt-1 w-full accent-[var(--svc-venue-ink)]"
                />
              </section>
            ) : null}

            <div className="h-px bg-line" />

            {selectedNodes.length > 1 ? (
              <section className="space-y-2">
                <p className="text-[12px] font-semibold text-ink">
                  Выделено: {selectedNodes.length}
                </p>
                <p className="text-[11px] text-muted">Группа / связка — слева в панели инструментов.</p>
                <AppButton type="button" service="venue" variant="outline" className="w-full" onClick={deleteSelected}>
                  Удалить
                </AppButton>
              </section>
            ) : selected && selected.kind !== "emoji" ? (
              <section className="space-y-3">
                <p className="text-[11px] font-bold uppercase tracking-wide text-muted">Объект</p>
                <input
                  value={selected.label ?? ""}
                  onChange={(e) => updateSelected({ label: e.target.value || null })}
                  placeholder="Название на схеме"
                  className="w-full rounded-[14px] border border-border-input bg-bg px-3 py-2.5 text-[14px] text-ink outline-none focus:border-svc-venue-ink"
                />
                <AppButton type="button" service="venue" variant="outline" className="w-full" onClick={deleteSelected}>
                  Удалить
                </AppButton>
              </section>
            ) : selected?.kind === "emoji" ? (
              <AppButton type="button" service="venue" variant="outline" className="w-full" onClick={deleteSelected}>
                Удалить смайлик
              </AppButton>
            ) : null}

            <div className="mt-auto space-y-2 border-t border-line pt-3">
              <p className="text-[12px] text-muted">
                {floors.length}{" "}
                {floors.length === 1 ? "этаж" : floors.length < 5 ? "этажа" : "этажей"}
                {" · "}
                {plan.label || "—"}
              </p>
              <AppButton type="button" service="venue" className="w-full" onClick={saveDraftNow}>
                Сохранить
              </AppButton>
            </div>
          </div>
        </aside>
      </div>
    </div>
  );
}

function TipBtn({
  children,
  onClick,
  tip,
  detail,
  disabled,
  active,
  side = "bottom",
  className = "",
}: {
  children: ReactNode;
  onClick?: () => void;
  tip: string;
  detail?: string;
  disabled?: boolean;
  active?: boolean;
  side?: "right" | "left" | "bottom";
  className?: string;
}) {
  const [open, setOpen] = useState(false);
  const tipClass =
    side === "right"
      ? "left-full top-1/2 ml-2 -translate-y-1/2"
      : side === "left"
        ? "right-full top-1/2 mr-2 -translate-y-1/2"
        : "left-1/2 top-full mt-2 -translate-x-1/2";

  const shellClass = `relative flex items-center justify-center rounded-[10px] transition ${
    active
      ? "bg-svc-venue text-svc-venue-ink shadow-elevate-sm"
      : "text-muted hover:bg-surface-soft hover:text-ink"
  } disabled:opacity-30 ${className || "h-9 w-9"}`;

  const tipEl = open ? (
    <div
      role="tooltip"
      className={`pointer-events-none absolute z-[90] w-max max-w-[220px] rounded-[12px] border border-line bg-ink px-2.5 py-2 text-left shadow-elevate-md ${tipClass}`}
    >
      <p className="text-[12px] font-bold text-white">{tip}</p>
      {detail ? <p className="mt-0.5 text-[11px] leading-snug text-white/75">{detail}</p> : null}
    </div>
  ) : null;

  if (!onClick) {
    return (
      <div
        className={shellClass}
        onMouseEnter={() => setOpen(true)}
        onMouseLeave={() => setOpen(false)}
        onFocus={() => setOpen(true)}
        onBlur={() => setOpen(false)}
      >
        {children}
        {tipEl}
      </div>
    );
  }

  return (
    <button
      type="button"
      disabled={disabled}
      onClick={onClick}
      aria-label={tip}
      className={shellClass}
      onMouseEnter={() => setOpen(true)}
      onMouseLeave={() => setOpen(false)}
      onFocus={() => setOpen(true)}
      onBlur={() => setOpen(false)}
    >
      {children}
      {tipEl}
    </button>
  );
}

function ColorRow({
  value,
  presets,
  onChange,
}: {
  value: string;
  presets: readonly string[];
  onChange: (value: string) => void;
}) {
  return (
    <div className="flex flex-wrap items-center gap-1.5">
      {presets.map((c) => (
        <TipBtn key={c} tip="Цвет" detail={c} side="bottom" onClick={() => onChange(c)}>
          <span
            className={`block h-6 w-6 rounded-full border transition ${
              value.toLowerCase() === c.toLowerCase()
                ? "border-svc-venue-ink ring-2 ring-svc-venue"
                : "border-line"
            }`}
            style={{ background: c }}
          />
        </TipBtn>
      ))}
      <label className="relative flex h-6 w-6 cursor-pointer items-center justify-center overflow-hidden rounded-full border border-line">
        <input
          type="color"
          value={/^#/.test(value) ? value : "#FFA39E"}
          onChange={(e) => onChange(e.target.value)}
          className="absolute inset-0 cursor-pointer opacity-0"
          title="Свой цвет"
        />
        <span className="text-[10px] font-bold text-muted">+</span>
      </label>
    </div>
  );
}

function PlanNodeShape({
  node,
  selected,
  guestDim = false,
}: {
  node: PlanNode;
  selected: boolean;
  guestDim?: boolean;
}) {
  const stroke = selected ? "#1A1D1E" : node.style.stroke;
  const strokeWidth = selected ? node.style.strokeWidth + 1 : node.style.strokeWidth;
  const common = {
    fill: node.style.fill ?? "transparent",
    stroke,
    strokeWidth,
    opacity: node.style.opacity,
    filter: selected ? "url(#nodeShadow)" : undefined,
  };
  const center = nodeCenter(node);
  const rotation = node.rotation ?? 0;
  const wrap = (children: ReactNode) => (
    <g
      transform={rotation ? `rotate(${rotation} ${center.x} ${center.y})` : undefined}
      opacity={guestDim ? 0.25 : undefined}
    >
      {children}
    </g>
  );

  if (node.kind === "text" && node.frame) {
    const { x, y, w, h } = node.frame;
    return wrap(
      <>
        <text
          x={x + w / 2}
          y={y + h / 2}
          textAnchor="middle"
          dominantBaseline="central"
          fill="#1A1D1E"
          fontSize={Math.max(12, Math.min(h * 0.7, 28))}
          fontWeight={650}
          style={{ pointerEvents: "none", fontFamily: "var(--font-manrope), sans-serif" }}
        >
          {node.label || "Текст"}
        </text>
        <rect x={x} y={y} width={w} height={h} fill="transparent" />
        {selected && <SelectionBox x={x} y={y} w={w} h={h} />}
      </>,
    );
  }

  if (node.kind === "emoji" && node.frame && node.label) {
    const { x, y, w, h } = node.frame;
    return wrap(
      <>
        <text
          x={x + w / 2}
          y={y + h / 2}
          textAnchor="middle"
          dominantBaseline="central"
          fontSize={h * 0.85}
          style={{ pointerEvents: "none", userSelect: "none" }}
        >
          {node.label}
        </text>
        {/* Невидимая зона клика / перетаскивания */}
        <rect x={x} y={y} width={w} height={h} fill="transparent" />
        {selected && <SelectionBox x={x} y={y} w={w} h={h} />}
      </>,
    );
  }

  const labelEl = node.label ? (
    <text
      x={
        node.frame
          ? node.frame.x + node.frame.w / 2
          : node.points
            ? node.points.reduce((s, p) => s + p.x, 0) / node.points.length
            : 0
      }
      y={
        node.frame
          ? node.frame.y + node.frame.h / 2
          : node.points
            ? node.points.reduce((s, p) => s + p.y, 0) / node.points.length
            : 0
      }
      textAnchor="middle"
      dominantBaseline="middle"
      fill="#1A1D1E"
      fontSize={13}
      fontWeight={650}
      style={{ pointerEvents: "none", fontFamily: "var(--font-manrope), sans-serif" }}
    >
      {node.label}
    </text>
  ) : null;

  if ((node.kind === "line" || node.kind === "path") && node.points && node.points.length >= 2) {
    return wrap(
      <>
        <polyline
          points={node.points.map((p) => `${p.x},${p.y}`).join(" ")}
          fill="none"
          stroke={stroke}
          strokeWidth={strokeWidth}
          strokeLinecap="round"
          strokeLinejoin="round"
          opacity={node.style.opacity}
        />
        {selected &&
          node.points.map((pt, i) => (
            <circle
              key={i}
              cx={pt.x}
              cy={pt.y}
              r={4}
              fill="#FFA39E"
              stroke="#B54B45"
              strokeWidth={1.5}
            />
          ))}
      </>,
    );
  }

  if (node.kind === "polygon" && node.points?.length) {
    return wrap(
      <>
        {node.holes?.length ? (
          <path d={ringsToPathD(node.points, node.holes)} fillRule="evenodd" {...common} />
        ) : (
          <polygon points={node.points.map((p) => `${p.x},${p.y}`).join(" ")} {...common} />
        )}
        {labelEl}
        {selected && node.frame && (
          <SelectionBox x={node.frame.x} y={node.frame.y} w={node.frame.w} h={node.frame.h} />
        )}
      </>,
    );
  }

  if (!node.frame) return null;
  const { x, y, w, h } = node.frame;

  if (node.kind === "ellipse") {
    return wrap(
      <>
        <ellipse cx={x + w / 2} cy={y + h / 2} rx={w / 2} ry={h / 2} {...common} />
        {labelEl}
        {selected && <SelectionBox x={x} y={y} w={w} h={h} />}
      </>,
    );
  }

  return wrap(
    <>
      <rect x={x} y={y} width={w} height={h} rx={node.style.radius} {...common} />
      {labelEl}
      {selected && <SelectionBox x={x} y={y} w={w} h={h} />}
    </>,
  );
}

function SelectionBox({ x, y, w, h }: { x: number; y: number; w: number; h: number }) {
  const handles: [number, number, Corner][] = [
    [x, y, "nw"],
    [x + w, y, "ne"],
    [x, y + h, "sw"],
    [x + w, y + h, "se"],
  ];
  return (
    <g>
      <rect
        x={x - 1}
        y={y - 1}
        width={w + 2}
        height={h + 2}
        fill="none"
        stroke="#B54B45"
        strokeWidth={1.5}
        opacity={0.7}
      />
      {handles.map(([hx, hy, corner]) => (
        <g key={corner}>
          {/* Большая зона захвата */}
          <circle cx={hx} cy={hy} r={10} fill="transparent" />
          <rect
            x={hx - 5}
            y={hy - 5}
            width={10}
            height={10}
            rx={2}
            fill="#fff"
            stroke="#B54B45"
            strokeWidth={2}
          />
        </g>
      ))}
    </g>
  );
}

function DraftShape({
  tool,
  a,
  b,
  shift,
  fill,
  stroke,
}: {
  tool: "rect" | "ellipse";
  a: PlanPoint;
  b: PlanPoint;
  shift: boolean;
  fill: string;
  stroke: string;
}) {
  const frame = normalizeFrame(a, b, shift);
  if (tool === "ellipse") {
    return (
      <ellipse
        cx={frame.x + frame.w / 2}
        cy={frame.y + frame.h / 2}
        rx={frame.w / 2}
        ry={frame.h / 2}
        fill={fill}
        fillOpacity={0.28}
        stroke={stroke}
        strokeWidth={1.5}
        strokeDasharray="5 4"
      />
    );
  }
  return (
    <rect
      x={frame.x}
      y={frame.y}
      width={frame.w}
      height={frame.h}
      rx={16}
      fill={fill}
      fillOpacity={0.28}
      stroke={stroke}
      strokeWidth={1.5}
      strokeDasharray="5 4"
    />
  );
}
