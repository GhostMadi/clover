"use client";

import {
  useCallback,
  useEffect,
  useRef,
  useState,
  type PointerEvent as ReactPointerEvent,
} from "react";
import { FilteredImage } from "@/features/post-create/components/filtered-image";
import type { ImageEditSettings } from "@/features/post-create/lib/image-edit-matrix";
import { POST_ASPECT_OPTIONS } from "@/features/post-create/lib/post-create-model";
import type { PostAspectRatioKind } from "@/features/post/lib/aspect-ratio";

/** Как Flutter `AppImageCropMath`: cover + zoom, pan в пределах кадра. */
export function coverRenderSize(
  viewportW: number,
  viewportH: number,
  imageW: number,
  imageH: number,
  zoom: number,
) {
  const z = Math.max(1, zoom);
  const cover = Math.max(viewportW / imageW, viewportH / imageH);
  return {
    width: imageW * cover * z,
    height: imageH * cover * z,
  };
}

/**
 * Смещение картинки в пикселях.
 * offset −0.5…0.5: «вниз/вправо» = картинка едет вниз/вправо → видно верх/лево (голову).
 */
export function coverOffsetPx(
  viewportW: number,
  viewportH: number,
  renderW: number,
  renderH: number,
  offsetX: number,
  offsetY: number,
) {
  const maxDx = Math.max(0, (renderW - viewportW) / 2);
  const maxDy = Math.max(0, (renderH - viewportH) / 2);
  const ox = Math.max(-0.5, Math.min(0.5, offsetX));
  const oy = Math.max(-0.5, Math.min(0.5, offsetY));
  return {
    left: (viewportW - renderW) / 2 + ox * 2 * maxDx,
    top: (viewportH - renderH) / 2 + oy * 2 * maxDy,
    maxDx,
    maxDy,
  };
}

type CropPreviewProps = {
  src: string;
  edit: ImageEditSettings;
  aspect: PostAspectRatioKind;
  zoom: number;
  offsetX: number;
  offsetY: number;
  onOffset: (x: number, y: number) => void;
};

/** Превью кропа с drag — совпадает с экспортом. */
export function CropPreview({
  src,
  edit,
  aspect,
  zoom,
  offsetX,
  offsetY,
  onOffset,
}: CropPreviewProps) {
  const frameRef = useRef<HTMLDivElement>(null);
  const [natural, setNatural] = useState<{ w: number; h: number } | null>(null);
  const [frame, setFrame] = useState({ w: 0, h: 0 });
  const dragRef = useRef<{
    id: number;
    startX: number;
    startY: number;
    origOx: number;
    origOy: number;
    maxDx: number;
    maxDy: number;
  } | null>(null);

  useEffect(() => {
    const img = new window.Image();
    img.onload = () => setNatural({ w: img.naturalWidth, h: img.naturalHeight });
    img.src = src;
  }, [src]);

  useEffect(() => {
    const el = frameRef.current;
    if (!el) return;
    const ro = new ResizeObserver(() => {
      const r = el.getBoundingClientRect();
      setFrame({ w: r.width, h: r.height });
    });
    ro.observe(el);
    const r = el.getBoundingClientRect();
    setFrame({ w: r.width, h: r.height });
    return () => ro.disconnect();
  }, [aspect]);

  const ratio = POST_ASPECT_OPTIONS.find((a) => a.kind === aspect)?.ratio ?? 4 / 3;

  let left = 0;
  let top = 0;
  let rw = frame.w;
  let rh = frame.h;
  let maxDx = 0;
  let maxDy = 0;
  if (natural && frame.w > 0 && frame.h > 0) {
    const render = coverRenderSize(frame.w, frame.h, natural.w, natural.h, zoom);
    rw = render.width;
    rh = render.height;
    const pos = coverOffsetPx(frame.w, frame.h, rw, rh, offsetX, offsetY);
    left = pos.left;
    top = pos.top;
    maxDx = pos.maxDx;
    maxDy = pos.maxDy;
  }

  const onPointerDown = useCallback(
    (e: ReactPointerEvent<HTMLDivElement>) => {
      if (e.button !== 0) return;
      e.currentTarget.setPointerCapture(e.pointerId);
      dragRef.current = {
        id: e.pointerId,
        startX: e.clientX,
        startY: e.clientY,
        origOx: offsetX,
        origOy: offsetY,
        maxDx,
        maxDy,
      };
    },
    [maxDx, maxDy, offsetX, offsetY],
  );

  const onPointerMove = useCallback(
    (e: ReactPointerEvent<HTMLDivElement>) => {
      const d = dragRef.current;
      if (!d || d.id !== e.pointerId) return;
      const dx = e.clientX - d.startX;
      const dy = e.clientY - d.startY;
      const nextX =
        d.maxDx > 0 ? Math.max(-0.5, Math.min(0.5, d.origOx + dx / (2 * d.maxDx))) : 0;
      const nextY =
        d.maxDy > 0 ? Math.max(-0.5, Math.min(0.5, d.origOy + dy / (2 * d.maxDy))) : 0;
      onOffset(nextX, nextY);
    },
    [onOffset],
  );

  const endDrag = useCallback((e: ReactPointerEvent<HTMLDivElement>) => {
    if (dragRef.current?.id === e.pointerId) dragRef.current = null;
  }, []);

  const canPan = maxDx > 0.5 || maxDy > 0.5;

  return (
    <div className="overflow-hidden rounded-[16px] bg-bg">
      <div
        ref={frameRef}
        className={`relative mx-auto w-full touch-none overflow-hidden bg-ink/5 ${
          canPan ? "cursor-grab active:cursor-grabbing" : "cursor-default"
        }`}
        style={{ aspectRatio: ratio }}
        onPointerDown={onPointerDown}
        onPointerMove={onPointerMove}
        onPointerUp={endDrag}
        onPointerCancel={endDrag}
      >
        {natural ? (
          <FilteredImage
            src={src}
            settings={edit}
            className="absolute max-w-none select-none"
            style={{
              width: rw,
              height: rh,
              left,
              top,
              pointerEvents: "none",
            }}
            draggable={false}
          />
        ) : (
          <div className="absolute inset-0 animate-pulse bg-line/40" />
        )}
      </div>
      <p className="px-3 py-2 text-center text-[11px] text-muted">
        {canPan
          ? "Тяни фото, чтобы выбрать кадр (голову / низ)"
          : "Увеличь масштаб — тогда можно сдвигать кадр"}
      </p>
    </div>
  );
}
