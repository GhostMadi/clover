"use client";

import {
  IMAGE_EDIT_TOOLS,
  IMAGE_EFFECT_PRESETS,
  formatSliderPercent,
  type ImageEditSettings,
  type ImageEditToolId,
} from "@/features/post-create/lib/image-edit-matrix";
import { CropPreview } from "@/features/post-create/components/crop-preview";
import { FilteredImage } from "@/features/post-create/components/filtered-image";
import { POST_ASPECT_OPTIONS } from "@/features/post-create/lib/post-create-model";
import type { PostAspectRatioKind } from "@/features/post/lib/aspect-ratio";

type EditorPanel = "adjust" | "effects" | "format";

type ImageEditorControlsProps = {
  previewUrl: string;
  edit: ImageEditSettings;
  aspect: PostAspectRatioKind;
  /** Кластер и т.п.: без смены соотношения, только зум/пан. */
  lockAspect?: boolean;
  zoom: number;
  offsetX: number;
  offsetY: number;
  activeTool: ImageEditToolId;
  panel: EditorPanel;
  onPanel: (p: EditorPanel) => void;
  onActiveTool: (t: ImageEditToolId) => void;
  onEdit: (patch: Partial<ImageEditSettings>) => void;
  onAspect: (kind: PostAspectRatioKind) => void;
  onZoom: (z: number) => void;
  onOffset: (x: number, y: number) => void;
};

/** Панель как в AppImageEditorPage: Настройка / Эффекты / Формат. */
export function ImageEditorControls({
  previewUrl,
  edit,
  aspect,
  lockAspect = false,
  zoom,
  offsetX,
  offsetY,
  activeTool,
  panel,
  onPanel,
  onActiveTool,
  onEdit,
  onAspect,
  onZoom,
  onOffset,
}: ImageEditorControlsProps) {
  const toolValue = edit[activeTool];
  const toolMeta = IMAGE_EDIT_TOOLS.find((t) => t.id === activeTool)!;

  return (
    <div className="flex flex-col gap-3">
      <CropPreview
        src={previewUrl}
        edit={edit}
        aspect={aspect}
        zoom={zoom}
        offsetX={offsetX}
        offsetY={offsetY}
        onOffset={onOffset}
      />

      <div className="min-h-[148px] rounded-[16px] border border-line bg-surface px-3 py-3">
        {panel === "adjust" ? (
          <div className="flex h-full flex-col gap-2">
            <div className="flex items-center justify-between gap-2">
              <span className="text-[13px] font-semibold text-ink">{toolMeta.label}</span>
              <span className="text-[13px] font-bold text-brand">
                {formatSliderPercent(toolValue)}
              </span>
            </div>
            <input
              type="range"
              min={-1}
              max={1}
              step={0.01}
              value={toolValue}
              onChange={(e) => onEdit({ [activeTool]: Number(e.target.value) })}
              className="w-full accent-[var(--brand)]"
            />
            <div className="mt-auto grid grid-cols-5 gap-1">
              {IMAGE_EDIT_TOOLS.map((t) => {
                const on = t.id === activeTool;
                return (
                  <button
                    key={t.id}
                    type="button"
                    onClick={() => onActiveTool(t.id)}
                    className={`rounded-[12px] px-1 py-2 text-center text-[11px] font-semibold leading-tight ${
                      on ? "bg-mint text-brand" : "text-muted hover:bg-bg"
                    }`}
                  >
                    {t.label}
                  </button>
                );
              })}
            </div>
          </div>
        ) : null}

        {panel === "effects" ? (
          <div className="flex gap-2.5 overflow-x-auto pb-1">
            {IMAGE_EFFECT_PRESETS.map((effect) => {
              const selected = edit.effectId === effect.id;
              return (
                <button
                  key={effect.id}
                  type="button"
                  onClick={() => onEdit({ effectId: effect.id })}
                  className="w-16 shrink-0 text-center"
                >
                  <div
                    className={`overflow-hidden rounded-[12px] border-2 ${
                      selected ? "border-brand" : "border-line"
                    }`}
                  >
                    <div className="aspect-square overflow-hidden bg-bg">
                      <FilteredImage
                        src={previewUrl}
                        effectIdOnly={effect.id}
                        className="h-full w-full object-cover"
                      />
                    </div>
                  </div>
                  <span
                    className={`mt-1 block truncate text-[11px] ${
                      selected ? "font-bold text-ink" : "font-medium text-muted"
                    }`}
                  >
                    {effect.name}
                  </span>
                </button>
              );
            })}
          </div>
        ) : null}

        {panel === "format" ? (
          <div className="flex flex-col gap-3">
            {lockAspect ? (
              <p className="rounded-[12px] bg-mint/70 px-3 py-2 text-[13px] font-semibold text-brand">
                Обложка · только 1:1
              </p>
            ) : (
              <div className="flex flex-wrap gap-2">
                {POST_ASPECT_OPTIONS.map((a) => (
                  <button
                    key={a.kind}
                    type="button"
                    onClick={() => onAspect(a.kind)}
                    className={`rounded-full px-3 py-1.5 text-[13px] font-semibold ${
                      aspect === a.kind
                        ? "bg-brand text-on-brand"
                        : "border border-line bg-bg text-ink"
                    }`}
                  >
                    {a.label}
                  </button>
                ))}
              </div>
            )}
            <label className="block text-[13px] font-semibold text-ink">
              Масштаб
              <input
                type="range"
                min={1}
                max={4}
                step={0.05}
                value={zoom}
                onChange={(e) => onZoom(Number(e.target.value))}
                className="mt-2 w-full accent-[var(--brand)]"
              />
            </label>
            <div className="grid grid-cols-2 gap-3">
              <label className="block text-[13px] font-semibold text-ink">
                Влево ← → вправо
                <input
                  type="range"
                  min={-0.5}
                  max={0.5}
                  step={0.01}
                  value={offsetX}
                  onChange={(e) => onOffset(Number(e.target.value), offsetY)}
                  className="mt-2 w-full accent-[var(--brand)]"
                />
              </label>
              <label className="block text-[13px] font-semibold text-ink">
                Вверх ↑ ↓ вниз
                <input
                  type="range"
                  min={-0.5}
                  max={0.5}
                  step={0.01}
                  value={offsetY}
                  onChange={(e) => onOffset(offsetX, Number(e.target.value))}
                  className="mt-2 w-full accent-[var(--brand)]"
                />
              </label>
            </div>
            <p className="text-[11px] leading-snug text-muted">
              Чтобы увидеть голову: потяни фото вниз или сдвинь ползунок «вниз». Если не
              двигается — увеличь масштаб.
            </p>
          </div>
        ) : null}
      </div>

      <div className="grid grid-cols-3 gap-1 rounded-[14px] bg-bg p-1">
        {(
          [
            ["adjust", "Настройка"],
            ["effects", "Эффекты"],
            ["format", "Формат"],
          ] as const
        ).map(([id, label]) => (
          <button
            key={id}
            type="button"
            onClick={() => onPanel(id)}
            className={`rounded-[12px] py-2 text-[13px] font-bold ${
              panel === id ? "bg-surface text-ink shadow-sm" : "text-muted"
            }`}
          >
            {label}
          </button>
        ))}
      </div>
    </div>
  );
}

export type { EditorPanel };
