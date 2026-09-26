"use client";

import { useMemo, useRef, useState, type ReactNode } from "react";
import { formatPriceKzt } from "@/features/booking/lib/booking-format";
import type { EmojiServiceBind } from "@/features/booking/lib/space-plan-bind-mock";
import { ringsToPathD } from "@/features/venue/lib/plan-boolean";
import type { PlanDocument, PlanNode } from "@/features/venue/lib/plan-editor-types";
import { nodeCenter } from "@/features/venue/lib/plan-ops";

type Props = {
  plan: PlanDocument;
  bindsByNode: Map<string, EmojiServiceBind>;
  selectedNodeIds?: string[];
  onEmojiClick?: (nodeId: string, emoji: string) => void;
  className?: string;
};

/**
 * Read-only схема для Записи: декор + кликабельные emoji с ценниками.
 * Рисуется из того же draft, что редактор Ресурсов.
 */
export function SpacePlanPreviewCanvas({
  plan,
  bindsByNode,
  selectedNodeIds = [],
  onEmojiClick,
  className,
}: Props) {
  const svgRef = useRef<SVGSVGElement | null>(null);
  const [pan, setPan] = useState({ x: 24, y: 24 });
  const [zoom, setZoom] = useState(0.72);
  const dragRef = useRef<{ sx: number; sy: number; ox: number; oy: number } | null>(null);
  const selected = useMemo(() => new Set(selectedNodeIds), [selectedNodeIds]);

  const sorted = useMemo(
    () => [...plan.nodes].sort((a, b) => a.zIndex - b.zIndex),
    [plan.nodes],
  );

  return (
    <div
      className={`relative overflow-hidden rounded-[24px] ${className ?? ""}`}
      style={{ background: plan.canvas.background }}
    >
      <svg
        ref={svgRef}
        className="h-full w-full touch-none"
        viewBox={`0 0 ${plan.canvas.width} ${plan.canvas.height}`}
        preserveAspectRatio="xMidYMid meet"
        onWheel={(e) => {
          e.preventDefault();
          const next = Math.min(2.2, Math.max(0.35, zoom * (e.deltaY > 0 ? 0.92 : 1.08)));
          setZoom(next);
        }}
        onPointerDown={(e) => {
          if (e.button !== 0) return;
          const target = e.target as Element;
          if (target.closest("[data-emoji-hit]")) return;
          (e.currentTarget as SVGSVGElement).setPointerCapture(e.pointerId);
          dragRef.current = { sx: e.clientX, sy: e.clientY, ox: pan.x, oy: pan.y };
        }}
        onPointerMove={(e) => {
          const d = dragRef.current;
          if (!d) return;
          setPan({
            x: d.ox + (e.clientX - d.sx),
            y: d.oy + (e.clientY - d.sy),
          });
        }}
        onPointerUp={() => {
          dragRef.current = null;
        }}
        onPointerCancel={() => {
          dragRef.current = null;
        }}
      >
        <g transform={`translate(${pan.x} ${pan.y}) scale(${zoom})`}>
          {sorted.map((node) => {
            const isPriceable = node.kind === "emoji" && node.role === "bookable";
            const bind = isPriceable ? bindsByNode.get(node.id) : undefined;
            const isSelected = selected.has(node.id);
            return (
              <g key={node.id}>
                <PreviewNodeShape node={node} selected={isSelected && isPriceable} />
                {isPriceable && node.frame ? (
                  <>
                    <rect
                      data-emoji-hit=""
                      x={node.frame.x - 4}
                      y={node.frame.y - 4}
                      width={node.frame.w + 8}
                      height={node.frame.h + 8}
                      fill="transparent"
                      className="cursor-pointer"
                      onClick={(e) => {
                        e.stopPropagation();
                        onEmojiClick?.(node.id, (node.label && node.label.trim()) || "📍");
                      }}
                    />
                    {bind ? (
                      <g style={{ pointerEvents: "none" }}>
                        <rect
                          x={node.frame.x + node.frame.w / 2 - 36}
                          y={node.frame.y + node.frame.h + 2}
                          width={72}
                          height={18}
                          rx={6}
                          fill="color-mix(in srgb, var(--svc-booking, #C5FEB7) 85%, #fff)"
                          stroke="color-mix(in srgb, var(--svc-booking-ink, #1A5C2E) 35%, transparent)"
                          strokeWidth={1}
                        />
                        <text
                          x={node.frame.x + node.frame.w / 2}
                          y={node.frame.y + node.frame.h + 11}
                          textAnchor="middle"
                          dominantBaseline="central"
                          fontSize={10}
                          fontWeight={700}
                          fill="#1A5C2E"
                          style={{ fontFamily: "var(--font-manrope), sans-serif" }}
                        >
                          {formatPriceKzt(bind.priceKzt)}
                        </text>
                      </g>
                    ) : null}
                  </>
                ) : null}
              </g>
            );
          })}
        </g>
      </svg>
      <div className="pointer-events-none absolute bottom-3 left-3 rounded-full bg-surface/85 px-2.5 py-1 text-[11px] font-semibold text-muted shadow-elevate-sm backdrop-blur">
        Зум · перетащите
      </div>
    </div>
  );
}

function PreviewNodeShape({ node, selected }: { node: PlanNode; selected: boolean }) {
  const stroke = selected ? "#1A5C2E" : node.style.stroke;
  const strokeWidth = selected ? node.style.strokeWidth + 1.5 : node.style.strokeWidth;
  const common = {
    fill: node.style.fill ?? "transparent",
    stroke,
    strokeWidth,
    opacity: node.style.opacity,
  };
  const center = nodeCenter(node);
  const rotation = node.rotation ?? 0;
  const wrap = (children: ReactNode) => (
    <g transform={rotation ? `rotate(${rotation} ${center.x} ${center.y})` : undefined}>
      {children}
    </g>
  );

  if (node.kind === "text" && node.frame) {
    const { x, y, w, h } = node.frame;
    return wrap(
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
      </text>,
    );
  }

  if (node.kind === "emoji" && node.frame) {
    const { x, y, w, h } = node.frame;
    return wrap(
      <>
        {selected ? (
          <rect
            x={x - 6}
            y={y - 6}
            width={w + 12}
            height={h + 12}
            rx={10}
            fill="color-mix(in srgb, #C5FEB7 45%, transparent)"
            stroke="#1A5C2E"
            strokeWidth={2}
          />
        ) : null}
        <text
          x={x + w / 2}
          y={y + h / 2}
          textAnchor="middle"
          dominantBaseline="central"
          fontSize={h * 0.85}
          style={{ pointerEvents: "none", userSelect: "none" }}
        >
          {node.label || "📍"}
        </text>
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
      <polyline
        points={node.points.map((p) => `${p.x},${p.y}`).join(" ")}
        fill="none"
        stroke={stroke}
        strokeWidth={strokeWidth}
        strokeLinecap="round"
        strokeLinejoin="round"
        opacity={node.style.opacity}
      />,
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
      </>,
    );
  }

  return wrap(
    <>
      <rect x={x} y={y} width={w} height={h} rx={node.style.radius} {...common} />
      {labelEl}
    </>,
  );
}
