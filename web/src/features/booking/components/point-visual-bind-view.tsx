"use client";

import { LayoutTemplate, Pencil } from "lucide-react";
import Link from "next/link";
import { useCallback, useEffect, useMemo, useState } from "react";
import { AppButton, AppButtonLink } from "@/components/shared/app-button";
import { BookingWorkspaceShell } from "@/features/booking/components/booking-workspace-shell";
import { SpacePlanPreviewCanvas } from "@/features/booking/components/space-plan-preview-canvas";
import { formatPriceKzt } from "@/features/booking/lib/booking-format";
import {
  clearEmojiBinds,
  listEmojiNodesForPoint,
  MOCK_BIND_SERVICES,
  MOCK_BIND_STAFF,
  readPointSpaceBind,
  setPointSpacePlan,
  upsertEmojiBinds,
  type EmojiServiceBind,
  type PointSpaceBindState,
} from "@/features/booking/lib/space-plan-bind-mock";
import {
  ensureSpacePlanDraft,
  listSpacePlans,
  type SpacePlanMeta,
} from "@/features/resources/lib/space-plans-mock";
import type { PlanDocument } from "@/features/venue/lib/plan-editor-types";
import { loadBuildingDraft } from "@/features/venue/lib/plan-storage";

type EmojiSpot = {
  nodeId: string;
  emoji: string;
  floorLabel: string;
  groupId: string | null;
};

type EmojiGroup = {
  glyph: string;
  spots: EmojiSpot[];
};

type EditTarget =
  | { mode: "one"; spot: EmojiSpot }
  | { mode: "group"; group: EmojiGroup };

function groupByGlyph(emojis: EmojiSpot[]): EmojiGroup[] {
  const map = new Map<string, EmojiSpot[]>();
  for (const e of emojis) {
    const list = map.get(e.emoji) ?? [];
    list.push(e);
    map.set(e.emoji, list);
  }
  return [...map.entries()].map(([glyph, spots]) => ({ glyph, spots }));
}

/**
 * Mock: холст схемы + правая колонка назначения услуги.
 */
export function PointVisualBindView({ pointId }: { pointId: string }) {
  const [state, setState] = useState<PointSpaceBindState>({ spacePlanId: null, binds: [] });
  const [plans, setPlans] = useState(() => [] as SpacePlanMeta[]);
  const [emojis, setEmojis] = useState<EmojiSpot[]>([]);
  const [planMeta, setPlanMeta] = useState<SpacePlanMeta | null>(null);
  const [floors, setFloors] = useState<PlanDocument[]>([]);
  const [floorKey, setFloorKey] = useState<string | null>(null);
  const [editing, setEditing] = useState<EditTarget | null>(null);
  const [pickServiceId, setPickServiceId] = useState<string>(MOCK_BIND_SERVICES[0].id);
  const [pickStaffId, setPickStaffId] = useState<string>("");
  const [withStaff, setWithStaff] = useState(false);

  const refresh = useCallback(() => {
    const bind = readPointSpaceBind(pointId);
    setState(bind);
    setPlans(listSpacePlans());
    if (bind.spacePlanId) ensureSpacePlanDraft(bind.spacePlanId);
    const listed = listEmojiNodesForPoint(pointId);
    setEmojis(listed.emojis);
    setPlanMeta(listed.plan);

    if (bind.spacePlanId) {
      const building = loadBuildingDraft(bind.spacePlanId);
      const nextFloors = building?.floors ?? [];
      setFloors(nextFloors);
      setFloorKey((prev) => {
        if (prev && nextFloors.some((f) => f.floorKey === prev)) return prev;
        return building?.activeFloorKey ?? nextFloors[0]?.floorKey ?? null;
      });
    } else {
      setFloors([]);
      setFloorKey(null);
    }
  }, [pointId]);

  useEffect(() => {
    refresh();
  }, [refresh]);

  const activeFloor = useMemo(
    () => floors.find((f) => f.floorKey === floorKey) ?? floors[0] ?? null,
    [floors, floorKey],
  );

  const bindByNode = useMemo(() => {
    const m = new Map<string, EmojiServiceBind>();
    for (const b of state.binds) m.set(b.nodeId, b);
    return m;
  }, [state.binds]);

  const groups = useMemo(() => groupByGlyph(emojis), [emojis]);

  const groupsOnFloor = useMemo(() => {
    if (!activeFloor) return groups;
    const ids = new Set(
      activeFloor.nodes
        .filter((n) => n.kind === "emoji" && n.role === "bookable")
        .map((n) => n.id),
    );
    return groups
      .map((g) => ({
        ...g,
        spots: g.spots.filter((s) => ids.has(s.nodeId)),
      }))
      .filter((g) => g.spots.length > 0);
  }, [groups, activeFloor]);

  const staffForService = useMemo(
    () => MOCK_BIND_STAFF.filter((s) => (s.serviceIds as readonly string[]).includes(pickServiceId)),
    [pickServiceId],
  );

  const selectedNodeIds = useMemo(() => {
    if (!editing) return [] as string[];
    return editing.mode === "one"
      ? [editing.spot.nodeId]
      : editing.group.spots.map((s) => s.nodeId);
  }, [editing]);

  const boundCount = state.binds.length;
  const placeCount = emojis.length;

  const openOne = (spot: EmojiSpot) => {
    const existing = bindByNode.get(spot.nodeId);
    setPickServiceId(existing?.serviceId ?? MOCK_BIND_SERVICES[0].id);
    setPickStaffId(existing?.staffId ?? "");
    setWithStaff(!!existing?.staffId);
    setEditing({ mode: "one", spot });
  };

  const openGroup = (group: EmojiGroup) => {
    const first = group.spots[0];
    const existing = first ? bindByNode.get(first.nodeId) : undefined;
    setPickServiceId(existing?.serviceId ?? MOCK_BIND_SERVICES[0].id);
    setPickStaffId(existing?.staffId ?? "");
    setWithStaff(!!existing?.staffId);
    setEditing({ mode: "group", group });
  };

  const openVisualCluster = (spot: EmojiSpot) => {
    if (!spot.groupId) return;
    const spots = emojis.filter((e) => e.groupId === spot.groupId);
    if (spots.length < 2) {
      openOne(spot);
      return;
    }
    openGroup({ glyph: spot.emoji, spots });
  };

  const onCanvasEmoji = (nodeId: string, emoji: string) => {
    const spot =
      emojis.find((e) => e.nodeId === nodeId) ??
      ({
        nodeId,
        emoji,
        floorLabel: activeFloor?.label || activeFloor?.floorKey || "",
        groupId: null,
      } satisfies EmojiSpot);
    openOne(spot);
  };

  const targetNodeIds = (target: EditTarget): string[] =>
    target.mode === "one" ? [target.spot.nodeId] : target.group.spots.map((s) => s.nodeId);

  const targetGlyph = (target: EditTarget): string =>
    target.mode === "one" ? target.spot.emoji : target.group.glyph;

  const saveBind = () => {
    if (!editing) return;
    const svc = MOCK_BIND_SERVICES.find((s) => s.id === pickServiceId);
    if (!svc) return;
    const staff =
      withStaff && pickStaffId
        ? (MOCK_BIND_STAFF.find((s) => s.id === pickStaffId) ?? null)
        : null;
    const glyph = targetGlyph(editing);
    const payload: EmojiServiceBind[] = targetNodeIds(editing).map((nodeId) => ({
      nodeId,
      emoji: glyph,
      serviceId: svc.id,
      serviceTitle: svc.title,
      priceKzt: svc.priceKzt,
      staffId: staff?.id ?? null,
      staffName: staff?.name ?? null,
    }));
    setState(upsertEmojiBinds(pointId, payload));
    refresh();
  };

  const clearTarget = () => {
    if (!editing) return;
    setState(clearEmojiBinds(pointId, targetNodeIds(editing)));
    setEditing(null);
    refresh();
  };

  const groupSummary = (group: EmojiGroup) => {
    const binds = group.spots
      .map((s) => bindByNode.get(s.nodeId))
      .filter((b): b is EmojiServiceBind => !!b);
    if (!binds.length) return null;
    const same =
      binds.length === group.spots.length &&
      binds.every(
        (b) =>
          b.serviceId === binds[0]!.serviceId &&
          (b.staffId ?? "") === (binds[0]!.staffId ?? ""),
      );
    if (same) return binds[0]!;
    return "mixed" as const;
  };

  const onPickPlan = (planId: string) => {
    if (!planId) {
      setPointSpacePlan(pointId, null);
      setEditing(null);
      refresh();
      return;
    }
    ensureSpacePlanDraft(planId);
    setPointSpacePlan(pointId, planId);
    setEditing(null);
    refresh();
  };

  return (
    <BookingWorkspaceShell
      pointId={pointId}
      title="Схема и ценники"
      lead="Клик по месту → назначьте услугу."
    >
      <div className="-mx-1 pb-8 sm:mx-0">
        <div className="grid gap-5 lg:grid-cols-[minmax(0,1fr)_300px] xl:grid-cols-[minmax(0,1fr)_320px] lg:items-start">
          {/* —— Холст —— */}
          <div className="relative min-w-0">
            {!state.spacePlanId ? (
              <div className="flex h-[min(68vh,680px)] flex-col items-center justify-center gap-3 rounded-[24px] bg-surface-soft px-6 text-center">
                <span className="flex h-14 w-14 items-center justify-center rounded-full bg-svc-booking text-svc-booking-ink">
                  <LayoutTemplate className="h-6 w-6" strokeWidth={2} />
                </span>
                <div>
                  <p className="text-[16px] font-bold text-ink">Нет схемы</p>
                  <p className="mt-1 text-[13px] text-muted">Выберите справа или создайте в Ресурсах.</p>
                </div>
                <Link
                  href="/app/settings/resources/space-plans"
                  className="text-[13px] font-bold text-svc-booking-ink underline-offset-2 hover:underline"
                >
                  Ресурсы → Схемы
                </Link>
              </div>
            ) : !activeFloor ? (
              <div className="flex h-[min(68vh,680px)] flex-col items-center justify-center gap-2 rounded-[24px] bg-surface-soft px-6 text-center">
                <p className="text-[15px] font-semibold text-ink">Пустой лист</p>
                <Link
                  href={`/app/settings/resources/space-plans/${planMeta?.id ?? ""}/edit`}
                  className="text-[13px] font-bold text-svc-booking-ink underline-offset-2 hover:underline"
                >
                  Нарисовать в Ресурсах
                </Link>
              </div>
            ) : (
              <div className="relative overflow-hidden rounded-[24px] shadow-elevate-sm ring-1 ring-line/60">
                {floors.length > 1 ? (
                  <div className="absolute left-3 top-3 z-10 flex flex-wrap gap-1">
                    {floors.map((f) => {
                      const active = f.floorKey === (activeFloor?.floorKey ?? floorKey);
                      return (
                        <button
                          key={f.floorKey}
                          type="button"
                          onClick={() => setFloorKey(f.floorKey)}
                          className={`rounded-full px-3 py-1 text-[12px] font-bold shadow-elevate-sm backdrop-blur transition ${
                            active
                              ? "bg-svc-booking text-svc-booking-ink"
                              : "bg-surface/90 text-muted hover:text-ink"
                          }`}
                        >
                          {f.label || f.floorKey}
                        </button>
                      );
                    })}
                  </div>
                ) : null}
                {planMeta ? (
                  <div className="absolute right-3 top-3 z-10 flex items-center gap-2 rounded-full bg-surface/90 px-3 py-1.5 shadow-elevate-sm backdrop-blur">
                    <p className="max-w-[140px] truncate text-[12px] font-bold text-ink">
                      {planMeta.title}
                    </p>
                    <span className="text-[11px] text-muted">
                      {boundCount}/{placeCount}
                    </span>
                  </div>
                ) : null}
                <SpacePlanPreviewCanvas
                  plan={activeFloor}
                  bindsByNode={bindByNode}
                  selectedNodeIds={selectedNodeIds}
                  onEmojiClick={onCanvasEmoji}
                  className="h-[min(68vh,680px)] w-full !rounded-none !border-0"
                />
              </div>
            )}
          </div>

          {/* —— Правая колонка —— */}
          <aside className="flex min-h-0 flex-col gap-4 lg:sticky lg:top-3 lg:max-h-[calc(100dvh-5.5rem)] lg:overflow-y-auto lg:pr-0.5">
            <div className="space-y-3">
              <label className="block">
                <span className="mb-1.5 block text-[12px] font-bold text-muted">Схема</span>
                <select
                  className="w-full rounded-[14px] border-0 bg-surface-soft px-3 py-2.5 text-[14px] font-semibold text-ink outline-none ring-1 ring-transparent focus:ring-svc-booking-ink/30"
                  value={state.spacePlanId ?? ""}
                  onChange={(e) => onPickPlan(e.target.value)}
                >
                  <option value="">Не выбрана</option>
                  {plans.map((p) => (
                    <option key={p.id} value={p.id}>
                      {p.title}
                    </option>
                  ))}
                </select>
              </label>
              <div className="flex flex-wrap gap-2">
                {planMeta ? (
                  <>
                    <AppButtonLink
                      href={`/app/settings/resources/space-plans/${planMeta.id}/edit`}
                      service="booking"
                      size="row"
                      variant="outline"
                      className="gap-1.5"
                    >
                      <Pencil className="h-3.5 w-3.5" strokeWidth={2.5} />
                      Правка
                    </AppButtonLink>
                    <AppButton
                      size="row"
                      variant="ghost"
                      service="booking"
                      onClick={() => onPickPlan("")}
                    >
                      Отвязать
                    </AppButton>
                  </>
                ) : plans.length === 0 ? (
                  <Link
                    href="/app/settings/resources/space-plans"
                    className="text-[13px] font-bold text-svc-booking-ink underline-offset-2 hover:underline"
                  >
                    Создать схему
                  </Link>
                ) : null}
              </div>
            </div>

            {state.spacePlanId ? (
              <div>
                <div className="mb-2 flex items-baseline justify-between gap-2">
                  <p className="text-[12px] font-bold text-muted">Места на этаже</p>
                  {groupsOnFloor.length > 0 ? (
                    <p className="text-[11px] text-muted">
                      {groupsOnFloor.reduce((n, g) => n + g.spots.length, 0)} шт.
                    </p>
                  ) : null}
                </div>
                {groupsOnFloor.length === 0 ? (
                  <p className="text-[13px] leading-snug text-muted">
                    Нет мест для ценника. Добавьте bookable-emoji в схеме.
                  </p>
                ) : (
                  <ul className="space-y-1.5">
                    {groupsOnFloor.map((group) => {
                      const summary = groupSummary(group);
                      const anySelected = group.spots.some((s) =>
                        selectedNodeIds.includes(s.nodeId),
                      );
                      return (
                        <li key={group.glyph}>
                          <div
                            className={`flex items-center gap-2 rounded-[14px] px-2.5 py-2 transition ${
                              anySelected ? "bg-svc-booking/45" : "bg-surface-soft hover:bg-svc-booking/25"
                            }`}
                          >
                            <button
                              type="button"
                              onClick={() =>
                                group.spots.length === 1
                                  ? openOne(group.spots[0]!)
                                  : openGroup(group)
                              }
                              className="flex min-w-0 flex-1 items-center gap-2 text-left"
                            >
                              <span className="text-[22px] leading-none">{group.glyph}</span>
                              <span className="truncate text-[13px] font-semibold text-ink">
                                ×{group.spots.length}
                              </span>
                              {summary && summary !== "mixed" ? (
                                <span className="truncate text-[12px] font-bold text-svc-booking-ink">
                                  {formatPriceKzt(summary.priceKzt)}
                                </span>
                              ) : summary === "mixed" ? (
                                <span className="text-[11px] font-semibold text-muted">разные</span>
                              ) : (
                                <span className="text-[11px] font-semibold text-muted">без цены</span>
                              )}
                            </button>
                            {group.spots.length > 1 ? (
                              <button
                                type="button"
                                onClick={() => openGroup(group)}
                                className="shrink-0 rounded-[10px] px-2 py-1 text-[11px] font-bold text-svc-booking-ink hover:bg-surface"
                              >
                                Всем
                              </button>
                            ) : null}
                          </div>
                          {anySelected && group.spots.length > 1 ? (
                            <div className="mt-1 flex flex-wrap gap-1 pl-1">
                              {group.spots.map((spot) => {
                                const b = bindByNode.get(spot.nodeId);
                                const sel = selectedNodeIds.includes(spot.nodeId);
                                return (
                                  <button
                                    key={spot.nodeId}
                                    type="button"
                                    onClick={() => openOne(spot)}
                                    className={`rounded-[10px] px-2 py-1 text-[11px] font-bold ${
                                      sel
                                        ? "bg-svc-booking text-svc-booking-ink"
                                        : "bg-surface-soft text-muted hover:text-ink"
                                    }`}
                                  >
                                    {b ? formatPriceKzt(b.priceKzt) : "—"}
                                  </button>
                                );
                              })}
                            </div>
                          ) : null}
                        </li>
                      );
                    })}
                  </ul>
                )}
              </div>
            ) : null}

            {editing ? (
              <div className="rounded-[20px] bg-svc-booking/30 p-4 ring-1 ring-svc-booking-ink/15">
                <div className="mb-4 flex items-center gap-3">
                  <span className="flex h-11 w-11 items-center justify-center rounded-[14px] bg-surface text-[24px] shadow-elevate-sm">
                    {targetGlyph(editing)}
                  </span>
                  <div className="min-w-0 flex-1">
                    <p className="text-[15px] font-bold text-ink">
                      {editing.mode === "group"
                        ? `Всем ×${editing.group.spots.length}`
                        : "Место"}
                    </p>
                    <p className="text-[12px] text-muted">Услуга на схеме</p>
                  </div>
                  <button
                    type="button"
                    className="text-[12px] font-bold text-muted hover:text-ink"
                    onClick={() => setEditing(null)}
                  >
                    ✕
                  </button>
                </div>

                {editing.mode === "one" &&
                editing.spot.groupId &&
                emojis.filter((e) => e.groupId === editing.spot.groupId).length > 1 ? (
                  <button
                    type="button"
                    onClick={() => openVisualCluster(editing.spot)}
                    className="mb-3 w-full rounded-[12px] bg-surface px-3 py-2 text-left text-[12px] font-bold text-svc-booking-ink hover:bg-surface-soft"
                  >
                    Всей связке (
                    {emojis.filter((e) => e.groupId === editing.spot.groupId).length})
                  </button>
                ) : null}

                <label className="mb-1 block text-[11px] font-bold text-muted">Услуга</label>
                <select
                  className="mb-3 w-full rounded-[12px] border-0 bg-surface px-3 py-2.5 text-[13px] font-semibold text-ink outline-none"
                  value={pickServiceId}
                  onChange={(e) => {
                    setPickServiceId(e.target.value);
                    setPickStaffId("");
                  }}
                >
                  {MOCK_BIND_SERVICES.map((s) => (
                    <option key={s.id} value={s.id}>
                      {s.title} · {formatPriceKzt(s.priceKzt)}
                    </option>
                  ))}
                </select>

                <div className="mb-3 grid grid-cols-2 gap-1.5 rounded-[12px] bg-surface/70 p-1">
                  <button
                    type="button"
                    onClick={() => {
                      setWithStaff(false);
                      setPickStaffId("");
                    }}
                    className={`rounded-[10px] py-2 text-[12px] font-bold transition ${
                      !withStaff ? "bg-svc-booking text-svc-booking-ink shadow-elevate-sm" : "text-muted"
                    }`}
                  >
                    Услуга
                  </button>
                  <button
                    type="button"
                    onClick={() => setWithStaff(true)}
                    className={`rounded-[10px] py-2 text-[12px] font-bold transition ${
                      withStaff ? "bg-svc-booking text-svc-booking-ink shadow-elevate-sm" : "text-muted"
                    }`}
                  >
                    + мастер
                  </button>
                </div>

                {withStaff ? (
                  <>
                    <label className="mb-1 block text-[11px] font-bold text-muted">Мастер</label>
                    <select
                      className="mb-3 w-full rounded-[12px] border-0 bg-surface px-3 py-2.5 text-[13px] font-semibold text-ink outline-none"
                      value={pickStaffId}
                      onChange={(e) => setPickStaffId(e.target.value)}
                    >
                      <option value="">Выберите</option>
                      {staffForService.map((s) => (
                        <option key={s.id} value={s.id}>
                          {s.name}
                        </option>
                      ))}
                    </select>
                  </>
                ) : null}

                <div className="flex gap-2">
                  <AppButton
                    service="booking"
                    size="row"
                    className="flex-1"
                    onClick={saveBind}
                    disabled={withStaff && !pickStaffId}
                  >
                    Сохранить
                  </AppButton>
                  <AppButton size="row" variant="ghost" onClick={clearTarget}>
                    Снять
                  </AppButton>
                </div>
              </div>
            ) : state.spacePlanId ? (
              <p className="rounded-[16px] bg-surface-soft px-3 py-3 text-[13px] leading-snug text-muted">
                Кликните место на плане или в списке.
              </p>
            ) : null}
          </aside>
        </div>
      </div>
    </BookingWorkspaceShell>
  );
}
